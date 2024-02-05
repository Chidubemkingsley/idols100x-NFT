// ChatWindow.js
import React, { useState, useEffect } from "react";
import { Input, Button } from "antd";

type Massage = {
  role: string;
  content: string;
};

const messages: Massage[] = [];

const ChatWindow = ({ onClose }: { onClose: () => void }) => {
  const [messageInput, setMessageInput] = useState("");
  const [chatHistory, setChatHistory] = useState<Massage[]>([]);

  const handleMessageSend = async (msg: string) => {

    try {
      const response = await fetch("http://127.0.0.1:8000/chat", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ query: msg }),
      });

      const data = await response.json();
      // 这里可以发送消息给后端，这里是一个示例
      messages.push({ role: "user", content: msg });
      messages.push({ role: "ikun", content: data.answer });
      setChatHistory(messages);
      setMessageInput("");
    } catch (error) {
      console.error("Error:", error);
    }
  };

  return (
    <div>
      <div style={{ marginBottom: "1rem" }}>
        {chatHistory.map((msg, index) => (
          <div key={index}>
            <strong>{msg.role}: </strong> {msg.content}
          </div>
        ))}

        <Input
          value={messageInput}
          onChange={(e) => setMessageInput(e.target.value)}
          placeholder="Type your message..."
          onPressEnter={(e) => handleMessageSend(messageInput)}
        />
      </div>
      <Button type="primary" onClick={() => handleMessageSend(messageInput)}>
        Send
      </Button>
    </div>
  );
};

export default ChatWindow;
