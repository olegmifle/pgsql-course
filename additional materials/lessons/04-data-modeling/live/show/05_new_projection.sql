CREATE TABLE live04_projection.projection_applied (
    generation integer NOT NULL,
    operation_id bigint NOT NULL REFERENCES live04_projection.operations(id),
    PRIMARY KEY (generation, operation_id)
);

CREATE TABLE live04_projection.turnover_v2 (
    generation integer NOT NULL,
    company_id bigint NOT NULL REFERENCES live04_projection.companies(id),
    business_date date NOT NULL,
    total_cents bigint NOT NULL,
    PRIMARY KEY (generation, company_id, business_date)
);
