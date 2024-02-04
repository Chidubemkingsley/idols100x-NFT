import React, { useEffect, useState } from "react";

import "@aptos-labs/wallet-adapter-ant-design/dist/index.css";

import { WalletSelector } from "@aptos-labs/wallet-adapter-ant-design";
import {
  Layout,
  Row,
  Col,
  Button,
  Spin,
  List,
  Checkbox,
  Input,
  Card,
  Image,
} from "antd";


import {
  useWallet,
  InputTransactionData,
} from "@aptos-labs/wallet-adapter-react";

import "@aptos-labs/wallet-adapter-ant-design/dist/index.css";
import { CheckboxChangeEvent } from "antd/es/checkbox";
import { Aptos } from "@aptos-labs/ts-sdk";

const aptos = new Aptos();

type Idol = {
  name: string;
  uri: string;
  description: string;
  address: string;
};

function App() {
  const { account, signAndSubmitTransaction } = useWallet();
  const [transactionInProgress, setTransactionInProgress] =
    useState<boolean>(false);
  const collectionAddress =
    "0xaa93b9da1e3ca3bae689040ee8c0b7c1dee4c82c5ee4e350c74195bc267b85cb";
  const [idols, setIdols] = useState<Idol[]>([]);

  const fetchIdolList = async () => {
    if (!account) return [];
    const rsps = await aptos.getAccountOwnedTokensFromCollectionAddress({
      accountAddress: account?.address,
      collectionAddress: collectionAddress,
    });
    let idols: Idol[] = [];
    for (let i = 0; i < rsps.length; i++) {
      const rep = rsps[i];
      idols.push({
        name: rep.current_token_data?.token_name ?? "",
        uri: rep.current_token_data?.token_uri ?? "",
        description: rep.current_token_data?.description ?? "",
        address: rep.current_token_data?.token_data_id ?? "",
      });
    }
    setIdols(idols);
    console.log(idols);
  };

  // const transferIdol = async (idol: Idol, recipient: string) => {
  //   const transaction = {
  //     collectionAddress: collectionAddress,
  //     tokenId: idol.address,
  //     recipient: recipient,
  //     memo: "transfer idol",
  //   };

  //   signAndSubmitTransaction(transaction);
  // }

  useEffect(() => {
    fetchIdolList();
  }, [account?.address]);

  return (
    <>
      <Layout>
        <Row align="middle">
          <Col span={10} offset={2}>
            <h1>idol-NFT</h1>
          </Col>
          <Col span={12} style={{ textAlign: "right", paddingRight: "200px" }}>
            <WalletSelector />
          </Col>
        </Row>
      </Layout>
      <Row align="middle">
          <Card title="My Idol List" style={{ width: 300 }}>
            <List
              itemLayout="horizontal"
              dataSource={idols}
              renderItem={(item) => (
                <List.Item>
                  <List.Item.Meta
                    title={item.name}
                    description={item.description}
                  />
                  <Image
                    width={100}
                    src={item.uri}
                  />
                </List.Item>
              )}
            />
          </Card>
        </Row>
    </>
  );
}

export default App;
