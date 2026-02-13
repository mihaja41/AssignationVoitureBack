
CREATE TYPE type_carburant_enum AS ENUM ('D', 'Es', 'H', 'El');

CREATE TABLE vehicule (
    id BIGSERIAL PRIMARY KEY,
    reference VARCHAR(100) NOT NULL,
    nb_place INT NOT NULL,
    type_carburant type_carburant_enum NOT NULL
);
