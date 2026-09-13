"""Domain wiring for pytest: the shared recorder, @case:N binding, and the
step plugins for every tier. The Node stack mirrors this in support/world.js.
"""

from __future__ import annotations

import pytest

from qa_core.recorder import qa, pytest_bdd_apply_tag, pytest_bdd_after_scenario  # noqa: F401

pytest_plugins = [
    "be.db.steps.cex_steps",
    "be.api.steps.minicex_steps",
    "be.api.steps.kraken_steps",
    "be.bot.steps.bot_steps",
    "be.api.steps.orders_steps",
    "be.api.steps.apikeys_steps",
    "be.api.steps.earn_steps",
]


def _case_id_of(node):
    marker = node.get_closest_marker("case_id")
    if marker is not None:
        return marker.args[0]
    for mark in node.iter_markers():
        if mark.name.startswith("case:"):
            return mark.name.split(":", 1)[1]
    return None


@pytest.fixture(autouse=True)
def bind_case(request, qa):
    case_id = _case_id_of(request.node)
    if case_id is None:
        return
    qa.case(case_id)
    for slot in ("store", "api", "site"):
        setattr(qa, slot, None)
    qa.screen = {}
