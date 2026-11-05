CREATE TABLE live04_projection.turnover_v1 (
    company_id bigint NOT NULL REFERENCES live04_projection.companies(id),
    business_date date NOT NULL,
    total_cents bigint NOT NULL,
    last_id bigint NOT NULL,
    PRIMARY KEY (company_id, business_date)
);

CREATE VIEW live04_projection.company_turnover AS
SELECT company_id, business_date, total_cents
FROM live04_projection.turnover_v1;
