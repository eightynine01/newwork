from typing import Generic, TypeVar, Type, Optional, List
from sqlalchemy.orm import Session
from app.db.database import Base
from app.models.session import Session as SessionModel
from app.models.template import Template
from app.models.skill import Skill
from app.models.workspace import Workspace
from app.models.permission import Permission

ModelType = TypeVar("ModelType", bound=Base)


class BaseRepository(Generic[ModelType]):
    """
    Base repository for CRUD operations.
    """

    def __init__(self, model: Type[ModelType]):
        """
        Initialize repository.

        Args:
            model: SQLAlchemy model class
        """
        self.model = model

    def get(self, db: Session, id: str) -> Optional[ModelType]:
        """
        Get a single record by ID.

        Args:
            db: Database session
            id: Record ID

        Returns:
            Model instance or None
        """
        return db.query(self.model).filter(self.model.id == id).first()

    def get_all(self, db: Session, skip: int = 0, limit: int = 100) -> List[ModelType]:
        """
        Get all records with pagination.

        Args:
            db: Database session
            skip: Number of records to skip
            limit: Maximum number of records to return

        Returns:
            List of model instances
        """
        return db.query(self.model).offset(skip).limit(limit).all()

    def create(self, db: Session, obj_in: dict) -> ModelType:
        """
        Create a new record.

        Args:
            db: Database session
            obj_in: Dictionary with model data

        Returns:
            Created model instance
        """
        db_obj = self.model(**obj_in)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def update(self, db: Session, db_obj: ModelType, obj_in: dict) -> ModelType:
        """
        Update a record.

        Args:
            db: Database session
            db_obj: Model instance to update
            obj_in: Dictionary with updated fields

        Returns:
            Updated model instance
        """
        for field, value in obj_in.items():
            setattr(db_obj, field, value)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def delete(self, db: Session, id: str) -> Optional[ModelType]:
        """
        Delete a record by ID.

        Args:
            db: Database session
            id: Record ID

        Returns:
            Deleted model instance or None
        """
        obj = db.query(self.model).filter(self.model.id == id).first()
        if obj:
            db.delete(obj)
            db.commit()
        return obj


class SessionRepository(BaseRepository[SessionModel]):
    """
    Repository for Session model.
    """

    def __init__(self):
        super().__init__(SessionModel)

    def get_by_path(self, db: Session, path: str) -> Optional[SessionModel]:
        """
        Get session by path.

        Args:
            db: Database session
            path: Session path

        Returns:
            Session instance or None
        """
        return db.query(self.model).filter(self.model.path == path).first()


class TemplateRepository(BaseRepository[Template]):
    """
    Repository for Template model.
    """

    def __init__(self):
        super().__init__(Template)

    def get_by_name(self, db: Session, name: str) -> Optional[Template]:
        """
        Get template by name.

        Args:
            db: Database session
            name: Template name

        Returns:
            Template instance or None
        """
        return db.query(self.model).filter(self.model.name == name).first()

    def get_by_scope(
        self, db: Session, scope: str, skip: int = 0, limit: int = 100
    ) -> List[Template]:
        """
        Get templates by scope.

        Args:
            db: Database session
            scope: Template scope ('workspace' or 'global')
            skip: Number of templates to skip
            limit: Maximum number of templates to return

        Returns:
            List of Template instances
        """
        return (
            db.query(self.model)
            .filter(self.model.scope == scope)
            .offset(skip)
            .limit(limit)
            .all()
        )


class SkillRepository(BaseRepository[Skill]):
    """
    Repository for Skill model.
    """

    def __init__(self):
        super().__init__(Skill)

    def get_by_name(self, db: Session, name: str) -> Optional[Skill]:
        """
        Get skill by name.

        Args:
            db: Database session
            name: Skill name

        Returns:
            Skill instance or None
        """
        return db.query(self.model).filter(self.model.name == name).first()


class WorkspaceRepository(BaseRepository[Workspace]):
    """
    Repository for Workspace model.
    """

    def __init__(self):
        super().__init__(Workspace)

    def get_active(self, db: Session) -> Optional[Workspace]:
        """
        Get the active workspace.

        Args:
            db: Database session

        Returns:
            Active Workspace instance or None
        """
        return db.query(self.model).filter(self.model.is_active).first()

    def set_active(self, db: Session, id: str) -> Optional[Workspace]:
        """
        Set a workspace as active (deactivates others).

        Args:
            db: Database session
            id: Workspace ID

        Returns:
            Updated Workspace instance or None
        """
        # Deactivate all workspaces
        db.query(self.model).update({"is_active": False})

        # Activate the specified workspace
        workspace = self.get(db, id)
        if workspace:
            workspace.is_active = True
            db.commit()
            db.refresh(workspace)

        return workspace

    def get_by_path(self, db: Session, path: str) -> Optional[Workspace]:
        """
        Get workspace by path.

        Args:
            db: Database session
            path: Workspace path

        Returns:
            Workspace instance or None
        """
        return db.query(self.model).filter(self.model.path == path).first()


class PermissionRepository(BaseRepository[Permission]):
    """
    Repository for Permission model.
    """

    def __init__(self):
        super().__init__(Permission)

    def get_pending(self, db: Session) -> List[Permission]:
        """
        Get all pending permissions.

        Args:
            db: Database session

        Returns:
            List of pending Permission instances
        """
        return (
            db.query(self.model)
            .filter(self.model.status == "pending")
            .order_by(self.model.created_at.desc())
            .all()
        )

    def get_by_session_id(self, db: Session, session_id: str) -> List[Permission]:
        """
        Get permissions for a session.

        Args:
            db: Database session
            session_id: Session ID

        Returns:
            List of Permission instances
        """
        return (
            db.query(self.model)
            .filter(self.model.session_id == session_id)
            .order_by(self.model.created_at.desc())
            .all()
        )

    def get_history(
        self, db: Session, skip: int = 0, limit: int = 100
    ) -> List[Permission]:
        """
        Get permission history (non-pending).

        Args:
            db: Database session
            skip: Number of records to skip
            limit: Maximum number of records to return

        Returns:
            List of Permission instances
        """
        return (
            db.query(self.model)
            .filter(self.model.status != "pending")
            .order_by(self.model.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )


# Repository instances
session_repository = SessionRepository()
template_repository = TemplateRepository()
skill_repository = SkillRepository()
workspace_repository = WorkspaceRepository()
permission_repository = PermissionRepository()
