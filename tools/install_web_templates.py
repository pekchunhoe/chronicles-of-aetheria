"""Install only the official pinned single-threaded Web template ZIPs.

Reads the central directory and selected entries using HTTP ranges, avoiding a
1.28 GB all-platform download. HTTPS source, exact version, and ZIP CRC verified.
No credentials, global installs, or third-party Python dependencies.
"""
import argparse
import io
from pathlib import Path
import urllib.request
import zipfile

VERSION = "4.7.2"
URL = f"https://godot-releases.nbg1.your-objectstorage.com/{VERSION}-stable/Godot_v{VERSION}-stable_export_templates.tpz"


class RemoteArchive(io.RawIOBase):
    def __init__(self):
        super().__init__()
        with urllib.request.urlopen(urllib.request.Request(URL, method="HEAD"), timeout=30) as response:
            self.length = int(response.headers["Content-Length"])
        self.position = 0

    def seekable(self):
        return True

    def readable(self):
        return True

    def tell(self):
        return self.position

    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else (self.position if whence == 1 else self.length) + offset
        return self.position

    def read(self, size=-1):
        size = self.length - self.position if size < 0 else min(size, self.length - self.position)
        if size <= 0:
            return b""
        request = urllib.request.Request(URL, headers={"Range": f"bytes={self.position}-{self.position + size - 1}"})
        with urllib.request.urlopen(request, timeout=60) as response:
            if response.status != 206:
                raise RuntimeError("Server did not honor byte ranges; install the full official template package instead.")
            contents = response.read()
        if len(contents) != size:
            raise RuntimeError("Truncated archive range")
        self.position += size
        return contents


def main():
    project = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--destination", type=Path, default=project / f".tools/godot-{VERSION}/editor_data/export_templates/{VERSION}.stable")
    parser.add_argument("--list", action="store_true", help="List Web template entries without installing")
    arguments = parser.parse_args()
    with zipfile.ZipFile(RemoteArchive()) as archive:
        if arguments.list:
            for entry in archive.infolist():
                if "/web" in entry.filename:
                    print(entry.filename, entry.file_size, entry.compress_size)
            return
        version = archive.read("templates/version.txt").decode().strip()
        if version != f"{VERSION}.stable":
            raise RuntimeError(f"Unexpected template version: {version}")
        arguments.destination.mkdir(parents=True, exist_ok=True)
        for name in ("web_nothreads_release.zip", "web_nothreads_debug.zip"):
            entry = archive.getinfo("templates/" + name)
            print(f"Downloading {name}: {entry.compress_size:,} bytes", flush=True)
            contents = archive.read(entry)
            with zipfile.ZipFile(io.BytesIO(contents)) as inner:
                if inner.testzip() is not None:
                    raise RuntimeError("Corrupt inner template ZIP")
            (arguments.destination / name).write_bytes(contents)
            print(f"Installed {name}; outer and inner ZIP CRC checks passed", flush=True)
        (arguments.destination / "version.txt").write_text(version + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
