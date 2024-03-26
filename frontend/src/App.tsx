import React, { useEffect, useState } from "react";

import "@aptos-labs/wallet-adapter-ant-design/dist/index.css";

import { WalletSelector } from "@aptos-labs/wallet-adapter-ant-design";
import {
  Layout,
  Row,
  Col,
  Button,
  List,
  Card,
  Image,
  Modal,
} from "antd";

import {
  useWallet,
  InputTransactionData,
} from "@aptos-labs/wallet-adapter-react";

import "@aptos-labs/wallet-adapter-ant-design/dist/index.css";
import { CheckboxChangeEvent } from "antd/es/checkbox";
import { Aptos } from "@aptos-labs/ts-sdk";
import ChatWindow from "./Chat";

const aptos = new Aptos();

type Idol = {
  name: string;
  uri: string;
  description: string;
  address: string;
};

function Idol() {
  const { account, signMessage } = useWallet();
  const [isChatWindowVisible, setChatWindowVisible] = useState(false);

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

  const signNFT = async (idol: Idol) => {
    if (!account) return;
    const message = `${idol.name}`;
    const signature = await signMessage({ nonce: "1234034", message });
    console.log(signature);
  };

  const handleChatButtonClick = (idol: Idol) => {
    setChatWindowVisible(true);
  };

  const handleChatWindowClose = () => {
    setChatWindowVisible(false);
  };

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
        <List
          itemLayout="horizontal"
          dataSource={idols}
          renderItem={(item) => (
            <List.Item>
              <Card
                style={{
                  width: 300,
                }}
                cover={<Image width="100%" src={item.uri} />}
                actions={[
                  <Button onClick={() => handleChatButtonClick(item)}>
                    Chat
                  </Button>,
           
                  <Button onClick={() => signNFT(item)}><a href="https://app.embedbase.xyz/dashboard/explorer/ikun" target="_blank" rel="noopener noreferrer">
                  Edit
                </a></Button>,
                 
                  <Button onClick={() => signNFT(item)}>transfer</Button>,
                ]}
                title="My Idol List"
              >
                <List.Item.Meta
                  title={item.name}
                  description={item.description}
                />
              </Card>
            </List.Item>
          )}
        />
        <Modal
          title="Chat with Support"
          visible={isChatWindowVisible}
          onCancel={handleChatWindowClose}
          footer={null}
        >
          <ChatWindow onClose={handleChatWindowClose} />
        </Modal>
      </Row>
    </>
  );
}

export default Idol;
