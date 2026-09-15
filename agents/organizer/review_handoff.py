"""
agents/organizer/review_handoff.py

The Organizer agent's responsibility at pipeline stage 7 for Medicine:
open the mandatory sensitive_domain review_queue row and (optionally)
notify a reviewer.

Per LD-02 §3 (Organizer role): the Organizer routes items to human review;
it does NOT itself decide the review outcome. The trust state machine
in services/trust/state_machine.py owns transitions. This agent only
calls open_sensitive_domain_review() and records the event.

MUST NOT: skip the review row for any Medicine resource, regardless of
how obviously safe the content seems. See LD-02 §2 hard rule.
"""
import uuid
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession

from services.trust.review_queue import open_sensitive_domain_review


async def handoff_medicine_resource(
    session: AsyncSession,
    resource_id: uuid.UUID,
) -> uuid.UUID:
    """Open the mandatory sensitive_domain review row for a Medicine resource.

    Called at pipeline stage 7 (ED-01 §3 stage 7) for every resource
    in the medicine vertical. Returns the review_id of the new row.

    This function does NOT advance trust_state — that happens only after
    a reviewer resolves the row via the review console.
    """
    row = await open_sensitive_domain_review(session, resource_id)
    return row.review_id


async def handoff_pipeline_failure(
    session: AsyncSession,
    resource_id: uuid.UUID,
    reason_code: str,
    note: Optional[str] = None,
) -> uuid.UUID:
    """Open a review row for a pipeline failure at stages 2, 3, 6, or 8.

    reason_code values per ED-04 §9:
      ambiguous_provenance, low_ai_confidence, canonicalization_ambiguous,
      high_value_source, user_flagged, contradiction_detected
    """
    from services.trust.review_queue import open_review
    row = await open_review(
        session=session,
        subject_type="resource",
        subject_id=resource_id,
        reason_code=reason_code,
    )
    return row.review_id
