{% docs prod_key_doc %}
The **product key** — the natural identifier of a product in the source system.

It is unique per product *at a point in time*, but repeats across historical
versions in the Type 6 dimension. That is exactly why `dim_product_t6` is keyed
by a surrogate key over `(prod_key, valid_from)` rather than by `prod_key`.

Any column can reuse this text by calling the doc function with this block's
name, `prod_key_doc`, from its `description:`.
{% enddocs %}

{% docs surrogate_key_doc %}
A **surrogate key**: a warehouse-generated identifier with no business meaning,
built by hashing the natural key plus the version's validity start. It gives the
fact table a single stable column to join on, and stays correct when the natural
key gains new versions.
{% enddocs %}
