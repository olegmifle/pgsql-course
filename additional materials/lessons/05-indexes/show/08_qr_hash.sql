DROP INDEX live5.qr_ind;
CREATE INDEX qr_ind_hash ON orders USING hash(qr);
