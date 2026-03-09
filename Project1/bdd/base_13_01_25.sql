

CREATE TABLE token (
    id SERIAL PRIMARY KEY,
    token_name TEXT NOT NULL UNIQUE,
    expire_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked BOOLEAN DEFAULT false
);




hotel_reservation=# select *  from reservation
hotel_reservation-#  ;
 id | lieu_depart_id | customer_id | passenger_nbr |    arrival_date     |         created_at         | lieu_destination_id
----+----------------+-------------+---------------+---------------------+----------------------------+---------------------
  1 |              1 | CLI001      |             4 | 2026-03-15 14:00:00 | 2026-03-04 07:38:56.158956 |                   4
  2 |              2 | CLI002      |             3 | 2026-03-15 16:00:00 | 2026-03-04 07:38:56.16998  |                   5
  3 |              1 | CLI003      |             6 | 2026-03-15 09:00:00 | 2026-03-04 07:38:56.176714 |                   6
  4 |              3 | CLI004      |             2 | 2026-03-15 14:00:00 | 2026-03-04 07:38:56.183577 |                   4
  5 |              1 | CLI005      |            10 | 2026-03-15 11:00:00 | 2026-03-04 07:38:56.190327 |                   5
  6 |              2 | CLI006      |             4 | 2026-03-16 10:00:00 | 2026-03-04 07:38:56.198963 |                   4
  7 |              1 | CLI007      |             3 | 2026-03-16 15:00:00 | 2026-03-04 07:38:56.206655 |                   6
  8 |              3 | CLI008      |             5 | 2026-03-16 12:00:00 | 2026-03-04 07:38:56.214039 |                   5
  9 |              1 | CLI009      |             2 | 2026-03-20 09:00:00 | 2026-03-04 07:38:56.22302  |                   4
 10 |              2 | CLI010      |             4 | 2026-03-20 14:00:00 | 2026-03-04 07:38:56.230106 |                   5
(10 rows)


hotel_reservation=# select *  from Lieu  ;
 id |     code     |           libelle           |         created_at
----+--------------+-----------------------------+----------------------------
  1 | COLBERT      | Hotel Colbert, Antananarivo | 2026-03-04 07:37:00.400067
  2 | CARLTON      | Hotel Carlton, Antananarivo | 2026-03-04 07:37:00.400067
  3 | IBIS         | Hotel Ibis, Antananarivo    | 2026-03-04 07:37:00.400067
  4 | IVATO        | Ivato Airport, Antananarivo | 2026-03-04 07:37:00.400067
  5 | NOSY_BE      | Nosy Be Airport             | 2026-03-04 07:37:00.400067
  6 | SAINTE_MARIE | Sainte-Marie Airport        | 2026-03-04 07:37:00.400067
  7 | ANTALAHA     | Antalaha Airport            | 2026-03-04 07:37:00.400067
  8 | SAMBAVA      | Sambava Airport             | 2026-03-04 07:37:00.400067
(8 rows)

INSERT into  distance  ( from_lieu_id  ,  to_lieu_id  ,  km_distance ) VALUES (4,4,0) ; 


 hotel_reservation=# select *  from distance ;
 id | from_lieu_id | to_lieu_id | km_distance |         created_at
----+--------------+------------+-------------+----------------------------
  1 |            1 |          4 |       35.50 | 2026-03-04 07:37:00.420853
  2 |            1 |          5 |      250.00 | 2026-03-04 07:37:00.420853
  3 |            1 |          6 |      180.00 | 2026-03-04 07:37:00.420853
  4 |            4 |          5 |      285.00 | 2026-03-04 07:37:00.420853
  5 |            4 |          6 |      200.00 | 2026-03-04 07:37:00.420853
  6 |            2 |          4 |       30.00 | 2026-03-04 07:38:56.244146
  7 |            3 |          4 |       28.00 | 2026-03-04 07:38:56.244146
  8 |            2 |          5 |      260.00 | 2026-03-04 07:38:56.244146
  9 |            3 |          5 |      255.00 | 2026-03-04 07:38:56.244146

hotel_reservation=#

