from pathlib import Path
from typing import List, Dict, Any, Optional
import mimetypes


class FileService:
    """
    Service for file system operations.
    """

    @staticmethod
    def resolve_path(path: str, base_dir: str = None) -> Path:
        """
        Resolve a file path to an absolute path.

        Args:
            path: The path to resolve
            base_dir: Optional base directory (defaults to current working directory)

        Returns:
            Resolved absolute Path object
        """
        if base_dir:
            base = Path(base_dir)
        else:
            base = Path.cwd()

        return (base / path).resolve()

    @staticmethod
    def read_file(path: str, encoding: str = "utf-8") -> str:
        """
        Read a file's contents.

        Args:
            path: The file path
            encoding: File encoding (default: utf-8)

        Returns:
            File contents as string

        Raises:
            FileNotFoundError: If file doesn't exist
            IOError: If file cannot be read
        """
        resolved_path = FileService.resolve_path(path)
        with open(resolved_path, "r", encoding=encoding) as f:
            return f.read()

    @staticmethod
    def write_file(path: str, content: str, encoding: str = "utf-8") -> None:
        """
        Write content to a file.

        Args:
            path: The file path
            content: Content to write
            encoding: File encoding (default: utf-8)

        Raises:
            IOError: If file cannot be written
        """
        resolved_path = FileService.resolve_path(path)
        # Create parent directories if they don't exist
        resolved_path.parent.mkdir(parents=True, exist_ok=True)

        with open(resolved_path, "w", encoding=encoding) as f:
            f.write(content)

    @staticmethod
    def file_exists(path: str) -> bool:
        """
        Check if a file exists.

        Args:
            path: The file path

        Returns:
            True if file exists, False otherwise
        """
        resolved_path = FileService.resolve_path(path)
        return resolved_path.is_file()

    @staticmethod
    def directory_exists(path: str) -> bool:
        """
        Check if a directory exists.

        Args:
            path: The directory path

        Returns:
            True if directory exists, False otherwise
        """
        resolved_path = FileService.resolve_path(path)
        return resolved_path.is_dir()

    @staticmethod
    def list_directory(path: str, recursive: bool = False) -> List[Dict[str, Any]]:
        """
        List contents of a directory.

        Args:
            path: The directory path
            recursive: Whether to list recursively

        Returns:
            List of file/directory info dictionaries
        """
        resolved_path = FileService.resolve_path(path)

        if not resolved_path.is_dir():
            raise FileNotFoundError(f"Directory not found: {resolved_path}")

        result = []

        if recursive:
            for item in resolved_path.rglob("*"):
                result.append(
                    {
                        "path": str(item.relative_to(resolved_path)),
                        "name": item.name,
                        "type": "directory" if item.is_dir() else "file",
                        "size": item.stat().st_size if item.is_file() else None,
                    }
                )
        else:
            for item in resolved_path.iterdir():
                result.append(
                    {
                        "path": item.name,
                        "name": item.name,
                        "type": "directory" if item.is_dir() else "file",
                        "size": item.stat().st_size if item.is_file() else None,
                    }
                )

        return result

    @staticmethod
    def delete_file(path: str) -> None:
        """
        Delete a file.

        Args:
            path: The file path

        Raises:
            FileNotFoundError: If file doesn't exist
            IOError: If file cannot be deleted
        """
        resolved_path = FileService.resolve_path(path)
        resolved_path.unlink()

    @staticmethod
    def create_directory(path: str, parents: bool = True) -> None:
        """
        Create a directory.

        Args:
            path: The directory path
            parents: Whether to create parent directories

        Raises:
            IOError: If directory cannot be created
        """
        resolved_path = FileService.resolve_path(path)
        resolved_path.mkdir(parents=parents, exist_ok=True)

    @staticmethod
    def get_file_info(path: str) -> Dict[str, Any]:
        """
        Get file information.

        Args:
            path: The file path

        Returns:
            Dictionary with file info

        Raises:
            FileNotFoundError: If file doesn't exist
        """
        resolved_path = FileService.resolve_path(path)
        stat = resolved_path.stat()

        return {
            "path": str(resolved_path),
            "name": resolved_path.name,
            "type": "directory" if resolved_path.is_dir() else "file",
            "size": stat.st_size if resolved_path.is_file() else None,
            "created": stat.st_ctime,
            "modified": stat.st_mtime,
            "is_file": resolved_path.is_file(),
            "is_dir": resolved_path.is_dir(),
        }

    @staticmethod
    def validate_directory(path: str) -> bool:
        """
        Check if a directory path exists and is accessible.

        Args:
            path: The directory path to validate

        Returns:
            True if path exists, is a directory, and is accessible
        """
        try:
            resolved_path = FileService.resolve_path(path)
            if not resolved_path.exists():
                return False
            if not resolved_path.is_dir():
                return False
            # Try to access the directory
            resolved_path.iterdir()
            return True
        except (PermissionError, OSError):
            return False

    @staticmethod
    def read_opencode_json(path: str) -> Dict[str, Any]:
        """
        Read opencode.json configuration from a directory.

        Args:
            path: Directory path containing opencode.json

        Returns:
            Dictionary with opencode.json content

        Raises:
            FileNotFoundError: If opencode.json doesn't exist
            IOError: If file cannot be read
        """
        resolved_path = FileService.resolve_path(path)
        opencode_path = resolved_path / "opencode.json"

        if not opencode_path.exists():
            raise FileNotFoundError(f"opencode.json not found in {path}")

        content = FileService.read_file(str(opencode_path))
        import json

        return json.loads(content)

    @staticmethod
    def write_opencode_json(path: str, config: Dict[str, Any]) -> None:
        """
        Write opencode.json configuration to a directory.

        Args:
            path: Directory path to write opencode.json
            config: Configuration dictionary to write

        Raises:
            IOError: If file cannot be written
        """
        import json

        resolved_path = FileService.resolve_path(path)
        opencode_path = resolved_path / "opencode.json"

        content = json.dumps(config, indent=2)
        FileService.write_file(str(opencode_path), content)

    @staticmethod
    def get_opencode_skills_path() -> Path:
        """
        Get the path to the .opencode/skills directory.

        Returns:
            Path to .opencode/skills directory
        """
        home = Path.home()
        skills_path = home / ".opencode" / "skills"
        return skills_path

    @staticmethod
    def list_skills_directory() -> List[Dict[str, Any]]:
        """
        List all skill directories in .opencode/skills.

        Returns:
            List of skill directories with metadata

        Raises:
            FileNotFoundError: If skills directory doesn't exist
        """
        skills_path = FileService.get_opencode_skills_path()

        if not skills_path.exists():
            return []

        skills = []
        for skill_dir in skills_path.iterdir():
            if skill_dir.is_dir():
                skill_info = {
                    "name": skill_dir.name,
                    "path": str(skill_dir),
                }

                # Try to read SKILL.md for metadata
                skill_md = skill_dir / "SKILL.md"
                if skill_md.exists():
                    try:
                        metadata = FileService._parse_skill_md(skill_md)
                        skill_info.update(metadata)
                    except Exception:
                        pass

                skills.append(skill_info)

        return skills

    @staticmethod
    def _parse_skill_md(md_path: Path) -> Dict[str, Any]:
        """
        Parse SKILL.md file to extract metadata.

        Args:
            md_path: Path to SKILL.md file

        Returns:
            Dictionary with skill metadata
        """
        content = FileService.read_file(str(md_path))

        metadata = {
            "description": "",
            "version": "",
            "category": "general",
            "tags": [],
        }

        lines = content.split("\n")
        for line in lines:
            line = line.strip()

            # Parse title (first heading)
            if line.startswith("# ") and not metadata.get("title"):
                metadata["title"] = line[2:].strip()

            # Parse description
            if line.lower().startswith("description:"):
                metadata["description"] = line.split(":", 1)[1].strip()

            # Parse version
            if line.lower().startswith("version:"):
                metadata["version"] = line.split(":", 1)[1].strip()

            # Parse category
            if line.lower().startswith("category:"):
                metadata["category"] = line.split(":", 1)[1].strip()

            # Parse tags (comma-separated)
            if line.lower().startswith("tags:"):
                tags_str = line.split(":", 1)[1].strip()
                metadata["tags"] = [
                    tag.strip() for tag in tags_str.split(",") if tag.strip()
                ]

        # If no explicit description, use the first paragraph
        if not metadata["description"]:
            in_paragraph = False
            for line in lines:
                stripped = line.strip()
                if stripped.startswith("#"):
                    in_paragraph = True
                elif in_paragraph and stripped and not stripped.startswith("#"):
                    metadata["description"] = stripped
                    break

        return metadata

    @staticmethod
    def delete_skill_folder(name: str) -> None:
        """
        Delete a skill folder.

        Args:
            name: Name of the skill folder

        Raises:
            FileNotFoundError: If skill directory doesn't exist
            IOError: If directory cannot be deleted
        """
        import shutil

        skills_path = FileService.get_opencode_skills_path()
        skill_path = skills_path / name

        if not skill_path.exists():
            raise FileNotFoundError(f"Skill directory not found: {name}")

        shutil.rmtree(skill_path)

    @staticmethod
    def get_skill_metadata(name: str) -> Dict[str, Any]:
        """
        Get metadata for a specific skill.

        Args:
            name: Name of the skill

        Returns:
            Dictionary with skill metadata

        Raises:
            FileNotFoundError: If skill directory doesn't exist
        """
        skills = FileService.list_skills_directory()
        for skill in skills:
            if skill["name"] == name:
                return skill

        raise FileNotFoundError(f"Skill not found: {name}")

    @staticmethod
    def get_mime_type(path: str) -> str:
        """
        Get the MIME type of a file based on its extension.

        Args:
            path: The file path

        Returns:
            MIME type string (e.g., 'text/plain', 'application/pdf')
        """
        # Initialize mimetypes database
        if not mimetypes.inited:
            mimetypes.init()

        # Add common types that might be missing
        mimetypes.add_type("text/markdown", ".md")
        mimetypes.add_type("application/x-yaml", ".yaml")
        mimetypes.add_type("application/x-yaml", ".yml")
        mimetypes.add_type("text/x-python", ".py")
        mimetypes.add_type("text/x-typescript", ".ts")
        mimetypes.add_type("text/x-typescript", ".tsx")
        mimetypes.add_type("application/javascript", ".js")
        mimetypes.add_type("application/javascript", ".jsx")
        mimetypes.add_type("text/x-dart", ".dart")
        mimetypes.add_type("text/x-rust", ".rs")
        mimetypes.add_type("text/x-go", ".go")
        mimetypes.add_type("text/x-swift", ".swift")
        mimetypes.add_type("text/x-kotlin", ".kt")

        mime_type, _ = mimetypes.guess_type(path)
        return mime_type or "application/octet-stream"

    @staticmethod
    def read_file_binary(path: str) -> bytes:
        """
        Read a file's contents as binary.

        Args:
            path: The file path

        Returns:
            File contents as bytes

        Raises:
            FileNotFoundError: If file doesn't exist
            IOError: If file cannot be read
        """
        resolved_path = FileService.resolve_path(path)
        with open(resolved_path, "rb") as f:
            return f.read()

    @staticmethod
    def get_file_size(path: str) -> int:
        """
        Get the size of a file in bytes.

        Args:
            path: The file path

        Returns:
            File size in bytes

        Raises:
            FileNotFoundError: If file doesn't exist
        """
        resolved_path = FileService.resolve_path(path)
        return resolved_path.stat().st_size
