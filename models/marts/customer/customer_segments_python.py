def model(dbt, session):
    import pandas as pd

    # Load customers table into pandas
    customers_df = dbt.ref("customers").to_pandas()

    # Normalize columns to lowercase for easier access
    customers_df.columns = customers_df.columns.str.lower()

    # If no rows, return empty
    if customers_df.empty:
        return pd.DataFrame(columns=["customer_id", "segment"])

    # Compute spend quartiles
    customers_df["spend_quartile"] = pd.qcut(
        customers_df["lifetime_spend"].fillna(0),
        q=4,
        labels=["Low", "Medium", "High", "VIP"],
        duplicates="drop"
    )

    result_df = customers_df[["customer_id", "lifetime_spend", "spend_quartile"]].rename(
        columns={
            "customer_id": "CUSTOMER_ID",
            "lifetime_spend": "LIFETIME_SPEND",
            "spend_quartile": "SEGMENT"
        }
    )

    return result_df
