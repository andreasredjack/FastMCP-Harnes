-- FastMCP-Harness reference schema for a first PostgreSQL trial.
-- No secrets, prompt payloads from users, or production data belong here.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS harness;

CREATE TYPE harness.lifecycle_status AS ENUM (
    'draft', 'in_review', 'approved', 'deprecated', 'blocked'
);

CREATE TYPE harness.evaluation_status AS ENUM (
    'pending', 'running', 'passed', 'failed', 'inconclusive'
);

CREATE TYPE harness.approval_status AS ENUM (
    'pending', 'approved', 'rejected', 'revoked'
);

CREATE TYPE harness.data_classification AS ENUM (
    'public', 'internal', 'confidential', 'restricted'
);

CREATE TABLE harness.ai_systems (
    ai_system_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_key TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    intended_purpose TEXT NOT NULL,
    deployment TEXT NOT NULL,
    owner TEXT NOT NULL,
    risk_owner TEXT NOT NULL,
    data_protection_owner TEXT NOT NULL,
    human_oversight_required BOOLEAN NOT NULL DEFAULT TRUE,
    autonomous_mutation_allowed BOOLEAN NOT NULL DEFAULT FALSE,
    eu_ai_act_category TEXT NOT NULL,
    eu_ai_act_review_reference TEXT NOT NULL,
    gdpr_review_status TEXT NOT NULL,
    iso42001_review_status TEXT NOT NULL,
    lifecycle_status harness.lifecycle_status NOT NULL DEFAULT 'draft',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE harness.models (
    model_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider TEXT NOT NULL,
    model_name TEXT NOT NULL,
    model_version TEXT,
    model_digest TEXT,
    endpoint_alias TEXT NOT NULL UNIQUE,
    model_group TEXT NOT NULL CHECK (model_group IN ('rag', 'coding', 'security-review')),
    data_processing_location TEXT NOT NULL,
    approved_for_use BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (provider, model_name, model_version)
);

CREATE TABLE harness.prompt_templates (
    prompt_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ai_system_id UUID NOT NULL REFERENCES harness.ai_systems(ai_system_id),
    prompt_key TEXT NOT NULL,
    purpose TEXT NOT NULL,
    data_classification harness.data_classification NOT NULL DEFAULT 'internal',
    owner TEXT NOT NULL,
    lifecycle_status harness.lifecycle_status NOT NULL DEFAULT 'draft',
    current_version INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (ai_system_id, prompt_key)
);

CREATE TABLE harness.prompt_versions (
    prompt_version_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prompt_id UUID NOT NULL REFERENCES harness.prompt_templates(prompt_id) ON DELETE RESTRICT,
    version INTEGER NOT NULL CHECK (version > 0),
    content TEXT NOT NULL,
    content_sha256 TEXT NOT NULL CHECK (content_sha256 ~ '^[a-f0-9]{64}$'),
    system_prompt_sha256 TEXT,
    model_id UUID REFERENCES harness.models(model_id),
    policy_sha256 TEXT,
    temperature NUMERIC(4,3),
    max_input_chars INTEGER CHECK (max_input_chars IS NULL OR max_input_chars > 0),
    status harness.lifecycle_status NOT NULL DEFAULT 'draft',
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    approved_at TIMESTAMPTZ,
    UNIQUE (prompt_id, version),
    UNIQUE (prompt_id, content_sha256)
);

CREATE TABLE harness.datasets (
    dataset_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dataset_key TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    purpose TEXT NOT NULL,
    classification harness.data_classification NOT NULL DEFAULT 'internal',
    contains_personal_data BOOLEAN NOT NULL DEFAULT FALSE,
    pii_scan_status TEXT NOT NULL DEFAULT 'pending',
    retention_days INTEGER NOT NULL CHECK (retention_days >= 0),
    owner TEXT NOT NULL,
    status harness.lifecycle_status NOT NULL DEFAULT 'draft',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE harness.dataset_versions (
    dataset_version_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dataset_id UUID NOT NULL REFERENCES harness.datasets(dataset_id) ON DELETE RESTRICT,
    version INTEGER NOT NULL CHECK (version > 0),
    manifest_sha256 TEXT NOT NULL CHECK (manifest_sha256 ~ '^[a-f0-9]{64}$'),
    item_count INTEGER NOT NULL CHECK (item_count >= 0),
    source_reference TEXT NOT NULL,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (dataset_id, version),
    UNIQUE (dataset_id, manifest_sha256)
);

CREATE TABLE harness.evaluation_suites (
    evaluation_suite_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    suite_key TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    purpose TEXT NOT NULL,
    evaluator_version TEXT NOT NULL,
    independent_judge_required BOOLEAN NOT NULL DEFAULT TRUE,
    owner TEXT NOT NULL,
    status harness.lifecycle_status NOT NULL DEFAULT 'draft',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE harness.evaluation_cases (
    evaluation_case_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    evaluation_suite_id UUID NOT NULL REFERENCES harness.evaluation_suites(evaluation_suite_id) ON DELETE RESTRICT,
    dataset_version_id UUID NOT NULL REFERENCES harness.dataset_versions(dataset_version_id) ON DELETE RESTRICT,
    case_key TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN (
        'prompt_injection', 'pii_redaction', 'secret_redaction',
        'hallucination', 'tool_allowlist', 'no_mutation',
        'quality', 'availability', 'policy_compliance'
    )),
    expected_behavior TEXT NOT NULL,
    severity TEXT NOT NULL DEFAULT 'medium',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (evaluation_suite_id, case_key)
);

CREATE TABLE harness.evaluation_runs (
    evaluation_run_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    evaluation_suite_id UUID NOT NULL REFERENCES harness.evaluation_suites(evaluation_suite_id),
    dataset_version_id UUID NOT NULL REFERENCES harness.dataset_versions(dataset_version_id),
    prompt_version_id UUID NOT NULL REFERENCES harness.prompt_versions(prompt_version_id),
    model_id UUID NOT NULL REFERENCES harness.models(model_id),
    gateway_alias TEXT NOT NULL,
    run_sha256 TEXT NOT NULL CHECK (run_sha256 ~ '^[a-f0-9]{64}$'),
    status harness.evaluation_status NOT NULL DEFAULT 'pending',
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    created_by TEXT NOT NULL,
    UNIQUE (run_sha256)
);

CREATE TABLE harness.evaluation_results (
    evaluation_result_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    evaluation_run_id UUID NOT NULL REFERENCES harness.evaluation_runs(evaluation_run_id) ON DELETE CASCADE,
    evaluation_case_id UUID NOT NULL REFERENCES harness.evaluation_cases(evaluation_case_id),
    result_status harness.evaluation_status NOT NULL,
    score NUMERIC(6,5) CHECK (score IS NULL OR score BETWEEN 0 AND 1),
    judge_name TEXT NOT NULL,
    judge_version TEXT NOT NULL,
    output_sha256 TEXT NOT NULL CHECK (output_sha256 ~ '^[a-f0-9]{64}$'),
    redaction_status TEXT NOT NULL DEFAULT 'not_checked',
    notes_redacted TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (evaluation_run_id, evaluation_case_id)
);

CREATE TABLE harness.approvals (
    approval_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_type TEXT NOT NULL CHECK (resource_type IN ('prompt_version', 'evaluation_run', 'release', 'evidence_bundle')),
    resource_id UUID NOT NULL,
    approver TEXT NOT NULL,
    role_name TEXT NOT NULL,
    status harness.approval_status NOT NULL DEFAULT 'pending',
    decision_reason TEXT,
    decided_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE harness.evidence_bundles (
    evidence_bundle_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ai_system_id UUID NOT NULL REFERENCES harness.ai_systems(ai_system_id),
    evaluation_run_id UUID REFERENCES harness.evaluation_runs(evaluation_run_id),
    git_revision TEXT NOT NULL,
    model_provenance_sha256 TEXT NOT NULL CHECK (model_provenance_sha256 ~ '^[a-f0-9]{64}$'),
    policy_sha256 TEXT NOT NULL CHECK (policy_sha256 ~ '^[a-f0-9]{64}$'),
    bundle_sha256 TEXT NOT NULL CHECK (bundle_sha256 ~ '^[a-f0-9]{64}$'),
    storage_reference TEXT NOT NULL,
    retention_until TIMESTAMPTZ NOT NULL,
    human_approval_required BOOLEAN NOT NULL DEFAULT TRUE,
    status harness.lifecycle_status NOT NULL DEFAULT 'draft',
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE harness.audit_events (
    audit_event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_time TIMESTAMPTZ NOT NULL DEFAULT now(),
    actor TEXT NOT NULL,
    action TEXT NOT NULL,
    resource_type TEXT NOT NULL,
    resource_id UUID,
    correlation_id TEXT NOT NULL,
    outcome TEXT NOT NULL,
    metadata_redacted JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX idx_prompt_versions_approved ON harness.prompt_versions(prompt_id, status);
CREATE INDEX idx_evaluation_runs_status ON harness.evaluation_runs(status, started_at);
CREATE INDEX idx_audit_events_correlation ON harness.audit_events(correlation_id);
CREATE INDEX idx_audit_events_time ON harness.audit_events(event_time);

CREATE OR REPLACE FUNCTION harness.prevent_approved_prompt_update()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status = 'approved' THEN
        RAISE EXCEPTION 'Approved prompt versions are immutable';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prompt_version_immutability
BEFORE UPDATE ON harness.prompt_versions
FOR EACH ROW EXECUTE FUNCTION harness.prevent_approved_prompt_update();
