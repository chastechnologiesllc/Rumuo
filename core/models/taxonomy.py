"""
core/models/taxonomy.py — ED-03 §2 taxonomy nodes.

New taxonomy nodes are DATA (loaded from db/seeds/ via scripts/seed_medicine_nigeria.py),
never hard-coded in application logic (ED-03 §2 + kickoff hard constraint §3).
"""
import uuid

from sqlalchemy import CheckConstraint, Column, ForeignKey, Index, Integer, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from core.db import Base


class TaxonomyNode(Base):
    """ED-03 §2 — profession / skill / business taxonomy tree.

    level=0 is the world anchor itself (e.g. "Medicine").
    level=1 are primary sub-trees; level=2 are leaf categories.

    Rule: stable enough for reliable indexing/filtering/analytics;
    extensible enough that new nodes are data additions, not code changes.
    """
    __tablename__ = "taxonomy_nodes"

    taxonomy_id  = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    world_anchor = Column(
        Text, nullable=False,
        # ED-03 §1: exactly three values — never invent a fourth (Doc 8 §15).
    )
    parent_id    = Column(UUID(as_uuid=True), ForeignKey("taxonomy_nodes.taxonomy_id"))
    name         = Column(Text, nullable=False)
    level        = Column(Integer, nullable=False)

    children = relationship("TaxonomyNode",
                            foreign_keys=[parent_id],
                            backref="parent")

    __table_args__ = (
        CheckConstraint("world_anchor IN ('profession', 'skill', 'business')",
                        name="taxonomy_nodes_world_anchor_check"),
        Index("taxonomy_nodes_world_anchor_idx", "world_anchor"),
        Index("taxonomy_nodes_parent_id_idx", "parent_id"),
    )
