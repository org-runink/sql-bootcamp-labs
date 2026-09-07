-- EDW — the store dimension, built entirely from a SEED.
--
-- The source system only ever gives us a store_key. Region is a business
-- attribute that lives in version control (seeds/store_master.csv), so the
-- dimension is the seed plus a surrogate key. A Type 1 dimension: no history,
-- the current row is the only row.

select
    {{ surrogate_key(['store_key']) }} as store_sk,
    store_key,
    store_name,
    region,
    country
from {{ ref('store_master') }}
