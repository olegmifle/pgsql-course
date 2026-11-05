CREATE INDEX orders_metadata_idx ON orders USING gin(metadata jsonb_path_ops);
