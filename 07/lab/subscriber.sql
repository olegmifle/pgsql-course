\set ON_ERROR_STOP on
CREATE SCHEMA hw07;
CREATE TABLE hw07.tenants(id int PRIMARY KEY,name text NOT NULL);
INSERT INTO hw07.tenants VALUES(42,'Магазин 42'),(7,'Магазин 7');
CREATE TABLE hw07.orders(
  id bigint PRIMARY KEY,
  tenant_id int NOT NULL REFERENCES hw07.tenants(id),
  status text NOT NULL CHECK(status IN ('draft','created','paid','cancelled')),
  total_amount numeric(12,2) NOT NULL CHECK(total_amount>=0),
  created_at timestamptz NOT NULL,
  reserved_until timestamptz,
  external_token uuid NOT NULL,
  receipt_token uuid NOT NULL DEFAULT gen_random_uuid()
);
CREATE TABLE hw07.progress(id int PRIMARY KEY,note text NOT NULL);
CREATE TABLE hw07.generated_ids(id bigserial PRIMARY KEY,note text NOT NULL);
CREATE TABLE hw07.local_audit(order_id bigint NOT NULL,operation text NOT NULL);
CREATE FUNCTION hw07.audit_order() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO hw07.local_audit VALUES(NEW.id,TG_OP);
  RETURN NEW;
END $$;
CREATE TRIGGER order_audit AFTER INSERT OR UPDATE ON hw07.orders
  FOR EACH ROW EXECUTE FUNCTION hw07.audit_order();
