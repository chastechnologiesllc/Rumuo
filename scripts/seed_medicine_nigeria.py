"""
scripts/seed_medicine_nigeria.py

Loads Medicine/Nigeria pilot seed data into the database.
Reads from db/seeds/medicine_nigeria/*.yaml — never hard-codes values.

Usage:
  python scripts/seed_medicine_nigeria.py --confirm

The --confirm flag is required to prevent accidental execution.
This script is idempotent: running it twice is safe (uses ON CONFLICT / upsert).

Per the kickoff hard constraint: do NOT run this until founder has explicitly
signed off on Rumuo_LD-01_Medicine_Taxonomy_and_Source_Allocation.md §3.
"""
import argparse
import asyncio
import os
import sys
import uuid
from pathlib import Path

import yaml

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from core.db import get_session, init_db
from core.models import AuthorityWeight, Question, TaxonomyNode


SEEDS_DIR = Path(__file__).parent.parent / "db" / "seeds" / "medicine_nigeria"


# ── Taxonomy loader ───────────────────────────────────────────────────────────
async def seed_taxonomy(session) -> dict[str, uuid.UUID]:
    """Load taxonomy.yaml into taxonomy_nodes. Returns name → taxonomy_id map."""
    data = yaml.safe_load((SEEDS_DIR / "taxonomy.yaml").read_text())
    id_map: dict[str, uuid.UUID] = {}

    async def insert_node(
        name: str, world_anchor: str, level: int, parent_id=None
    ) -> uuid.UUID:
        from sqlalchemy import select
        result = await session.execute(
            select(TaxonomyNode).where(
                TaxonomyNode.name == name,
                TaxonomyNode.world_anchor == world_anchor,
            )
        )
        existing = result.scalar_one_or_none()
        if existing:
            return existing.taxonomy_id

        node = TaxonomyNode(
            world_anchor=world_anchor,
            parent_id=parent_id,
            name=name,
            level=level,
        )
        session.add(node)
        await session.flush()
        return node.taxonomy_id

    async def walk(tree: dict, world_anchor: str, level: int, parent_id=None):
        node_id = await insert_node(
            name=tree["name"],
            world_anchor=world_anchor,
            level=level,
            parent_id=parent_id,
        )
        id_map[tree["name"]] = node_id
        for child in tree.get("children", []):
            await walk(child, world_anchor, level + 1, parent_id=node_id)

    # taxonomy.yaml top-level keys are world anchors. A world anchor may be a
    # single nested tree (profession/skill) or a list of independent roots
    # (business), so support both documented fixture shapes.
    for world_anchor, tree_or_roots in data.items():
        roots = tree_or_roots if isinstance(tree_or_roots, list) else [tree_or_roots]
        for tree in roots:
            await walk(tree, world_anchor=world_anchor, level=tree.get("level", 0))

    print(f"  taxonomy_nodes: {len(id_map)} nodes seeded")
    return id_map


# ── Questions loader ──────────────────────────────────────────────────────────
async def seed_questions(session) -> None:
    """Load questions.yaml into the questions table."""
    data = yaml.safe_load((SEEDS_DIR / "questions.yaml").read_text())
    count = 0
    for q in data:
        from sqlalchemy import select
        result = await session.execute(
            select(Question).where(Question.normalized_intent == q["id"])
        )
        if result.scalar_one_or_none():
            continue

        question = Question(
            question_text=q["text"],
            normalized_intent=q["id"],
        )
        session.add(question)
        count += 1

    print(f"  questions: {count} new rows seeded")


# ── Authority weights loader ──────────────────────────────────────────────────
async def seed_authority_weights(session) -> None:
    """Load authority_weights.yaml into the authority_weights table.

    NOTE: weight values in the YAML are illustrative starting points, not
    founder-approved final values. See file header for details.
    """
    data = yaml.safe_load((SEEDS_DIR / "authority_weights.yaml").read_text())
    count = 0
    for entry in data:
        claim_type = entry["claim_type"]
        jurisdiction = entry.get("jurisdiction", "Nigeria")
        for source_type, weight in entry["weights"].items():
            from sqlalchemy import select
            result = await session.execute(
                select(AuthorityWeight).where(
                    AuthorityWeight.claim_type == claim_type,
                    AuthorityWeight.source_type == source_type,
                    AuthorityWeight.jurisdiction == jurisdiction,
                )
            )
            if result.scalar_one_or_none():
                continue

            row = AuthorityWeight(
                claim_type=claim_type,
                source_type=source_type,
                jurisdiction=jurisdiction,
                weight=weight,
            )
            session.add(row)
            count += 1

    print(f"  authority_weights: {count} new rows seeded")


# ── Main ──────────────────────────────────────────────────────────────────────
async def main() -> None:
    parser = argparse.ArgumentParser(
        description="Seed Medicine/Nigeria pilot data. Requires --confirm."
    )
    parser.add_argument(
        "--confirm", action="store_true",
        help=(
            "Required flag. Confirms the founder has signed off on "
            "LD-01 §3 source allocation before seeding begins."
        ),
    )
    args = parser.parse_args()

    if not args.confirm:
        print(
            "STOPPED: --confirm flag is required.\n"
            "This flag confirms the founder has explicitly signed off on\n"
            "Rumuo_LD-01_Medicine_Taxonomy_and_Source_Allocation.md §3\n"
            "before any Researcher/acquisition activity begins (kickoff hard constraint).\n"
            "Re-run with: python scripts/seed_medicine_nigeria.py --confirm"
        )
        sys.exit(1)

    if not os.environ.get("DATABASE_URL"):
        print("ERROR: DATABASE_URL environment variable is not set.")
        sys.exit(1)

    print("Seeding Medicine/Nigeria pilot data...")
    init_db()

    async with get_session() as session:
        await seed_taxonomy(session)
        await seed_questions(session)
        await seed_authority_weights(session)

    print("Done. Seed complete.")


if __name__ == "__main__":
    asyncio.run(main())
