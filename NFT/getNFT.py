# Copyright © Aptos Foundation
# SPDX-License-Identifier: Apache-2.0

import asyncio
import json

from aptos_sdk.account import Account
from aptos_sdk.account_address import AccountAddress
from aptos_sdk.aptos_token_client import (
    AptosTokenClient,
    Collection,
    Object,
    PropertyMap,
    ReadObject,
    Token,
)
from aptos_sdk.async_client import FaucetClient, RestClient

import os
from dotenv import load_dotenv
load_dotenv()

# :!:>section_1
NODE_URL = os.getenv("APTOS_NODE_URL", "https://fullnode.devnet.aptoslabs.com/v1")
FAUCET_URL = os.getenv(
    "APTOS_FAUCET_URL",
    "https://faucet.devnet.aptoslabs.com",
)  # <:!:section_1


def get_owner(obj: ReadObject) -> AccountAddress:
    return obj.resources[Object].owner


# :!:>section_6
async def get_collection_data(
    token_client: AptosTokenClient, collection_addr: AccountAddress
) -> dict[str, str]:
    collection = (await token_client.read_object(collection_addr)).resources[Collection]
    return {
        "creator": str(collection.creator),
        "name": str(collection.name),
        "description": str(collection.description),
        "uri": str(collection.uri),
    }  # <:!:section_6


# :!:>get_token_data
async def get_token_data(
    token_client: AptosTokenClient, token_addr: AccountAddress
) -> dict[str, str]:
    token = (await token_client.read_object(token_addr)).resources[Token]
    return {
        "collection": str(token.collection),
        "description": str(token.description),
        "name": str(token.name),
        "uri": str(token.uri),
        "index": str(token.index),
    }  # <:!:get_token_data


async def main():
    # Create API and faucet clients.
    # :!:>section_1a
    rest_client = RestClient(NODE_URL)
    faucet_client = FaucetClient(FAUCET_URL, rest_client)  # <:!:section_1a

    # Create client for working with the token module.
    # :!:>section_1b
    token_client = AptosTokenClient(rest_client)  # <:!:section_1b

    # :!:>section_2
    PrivateKey = os.getenv("PrivateKey")

    alice = Account.load_key(PrivateKey)

    collection_name = "idol-demo"
    token_name = "ikun"

    # :!:>owners
    owners = {str(alice.address()): "Alice"}  # <:!:owners

    print("\n=== Addresses ===")
    print(f"Alice: {alice.address()}")

    # :!:>section_3
    alice_fund = faucet_client.fund_account(alice.address(), 100_000_000)  # <:!:section_3
    await asyncio.gather(*[alice_fund])

    print("\n=== Initial Coin Balances ===")
    alice_balance = rest_client.account_balance(alice.address())
    [alice_balance] = await asyncio.gather(*[alice_balance])
    print(f"Alice: {alice_balance}")

    print("\n=== Creating Collection and Token ===")

    # :!:>section_4
    txn_hash = await token_client.create_collection(
        alice,
        "Alice's simple collection",
        1,
        collection_name,
        "https://aptos.dev",
        True,
        True,
        True,
        True,
        True,
        True,
        True,
        True,
        True,
        0,
        1,
    )  # <:!:section_4
    await rest_client.wait_for_transaction(txn_hash)

    collection_addr = AccountAddress.for_named_collection(
        alice.address(), collection_name
    )

    # :!:>section_5
    txn_hash = await token_client.mint_token(
        alice,
        collection_name,
        "Alice's simple token",
        token_name,
        "https://raw.githubusercontent.com/realTaki/Aptos-hack-round-1/main/NFT/ikun.png",
        PropertyMap([]),
    )  # <:!:section_5
    await rest_client.wait_for_transaction(txn_hash)

    minted_tokens = await token_client.tokens_minted_from_transaction(txn_hash)
    assert len(minted_tokens) == 1

    collection_data = await get_collection_data(token_client, collection_addr)
    print(
        "\nCollection data: "
        + json.dumps({"address": str(collection_addr), **collection_data}, indent=4)
    )

    token_addr = minted_tokens[0]

    # Check the owner
    # :!:>section_7
    obj_resources = await token_client.read_object(token_addr)
    owner = str(get_owner(obj_resources))
    print(f"\nToken owner: {owners[owner]}")  # <:!:section_7
    token_data = await get_token_data(token_client, token_addr)
    print(
        "Token data: "
        + json.dumps(
            {"address": str(token_addr), "owner": owner, **token_data}, indent=4
        )
    )

    # Read the object owner one last time
    # :!:>section_11
    obj_resources = await token_client.read_object(token_addr)
    print(f"Token owner: {owners[str(get_owner(obj_resources))]}\n")  # <:!:section_11

    await rest_client.close()


if __name__ == "__main__":
    asyncio.run(main())