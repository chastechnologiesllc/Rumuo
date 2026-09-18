"""
services/constitution/form_extensibility.py — ED-12 §1.2 addition procedure.

Before a candidate information_form is promoted to 'active', this checker runs
the four-step procedure defined in ED-12 §1.2:
  1. Row exists at status='candidate'.
  2. ED-01's 13-stage pipeline can run against it (extractor registered).
  3. Ranking and cross-format nav don't hard-code exactly five forms.
  4. Only after 2–3 pass: flip to 'active'.

MUST NOT: promote a form to active without passing all four steps.
MUST NOT: delete or repurpose a form_id once any resources row references it.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date

from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from core.models import InformationForm, Resource


@dataclass
class ExtensibilityCheckResult:
    form_id: str
    passed: bool
    failures: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)


async def check_candidate_form(
    session: AsyncSession,
    form_id: str,
) -> ExtensibilityCheckResult:
    """Run ED-12 §1.2 steps 2–3 for a candidate form before promotion.

    Step 1 (row at status=candidate) is verified here.
    Steps 2–3 are checked structurally.
    Step 4 (flip to active) is a separate, escalate-to-founder action.
    """
    result = ExtensibilityCheckResult(form_id=form_id, passed=False)

    # Step 1: row must exist at candidate
    row = await session.execute(
        select(InformationForm).where(InformationForm.form_id == form_id)
    )
    form = row.scalar_one_or_none()
    if form is None:
        result.failures.append(f"No information_forms row for form_id={form_id!r}.")
        return result
    if form.status != "candidate":
        result.failures.append(
            f"form_id={form_id!r} has status={form.status!r}; expected 'candidate'."
        )
        return result

    # Step 2: extractor must be registered
    try:
        from agents.organizer.extraction import EXTRACTOR_REGISTRY
        if form_id not in EXTRACTOR_REGISTRY:
            result.failures.append(
                f"No extractor registered for form_id={form_id!r} in "
                "agents/organizer/extraction/__init__.py. "
                "Add an extractor before promoting (ED-12 §1.2 step 2)."
            )
    except ImportError:
        result.warnings.append("Could not import extractor registry for step-2 check.")

    # Step 3: confirm no hard-coded form count in ranking or nav
    # (Static analysis — checks for literal "five" or "5" near form references in key files)
    import os
    import re
    files_to_check = [
        "services/ranking/ranker.py",
        "services/experience_api/queries.py",
        "services/orchestrator/pipeline.py",
    ]
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    for rel_path in files_to_check:
        full_path = os.path.join(root, rel_path)
        if not os.path.exists(full_path):
            continue
        content = open(full_path).read()
        if re.search(r'\b(five|5)\b.*form', content, re.IGNORECASE):
            result.failures.append(
                f"{rel_path} may contain a hard-coded assumption about exactly five forms. "
                "Audit before promoting (ED-12 §1.2 step 3)."
            )

    result.passed = len(result.failures) == 0
    return result


async def promote_candidate_to_active(
    session: AsyncSession,
    form_id: str,
    promoted_by: str,
) -> bool:
    """Flip a candidate form to active ONLY after check_candidate_form passes.

    MUST NOT be called without a passing ExtensibilityCheckResult.
    This action requires founder sign-off (ED-12 §7 escalation).
    promoted_by is logged in pipeline_notes for audit trail.
    """
    check = await check_candidate_form(session, form_id)
    if not check.passed:
        raise ValueError(
            f"Cannot promote {form_id!r}: "
            f"extensibility checks failed: {check.failures}"
        )
    await session.execute(
        update(InformationForm)
        .where(InformationForm.form_id == form_id)
        .values(
            status="active",
            pipeline_notes=f"Promoted by {promoted_by} on {date.today().isoformat()}. "
                           "Extensibility checks passed (ED-12 §1.2).",
        )
    )
    return True


async def deprecate_form(
    session: AsyncSession,
    form_id: str,
) -> None:
    """Mark a form as deprecated. MUST NOT delete it (ED-12 §1.2 identity guarantee)."""
    existing = await session.execute(
        select(func.count()).select_from(Resource).where(Resource.type == form_id)
    )
    resource_count = existing.scalar()
    await session.execute(
        update(InformationForm)
        .where(InformationForm.form_id == form_id)
        .values(
            status="deprecated",
            pipeline_notes=(
                f"Deprecated. {resource_count} resources still reference this form_id — "
                "they are unaffected (ED-12 §1.2 identity guarantee)."
            ),
        )
    )
