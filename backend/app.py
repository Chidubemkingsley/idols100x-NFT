from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from embedbase_client import EmbedbaseClient

# read api key from .env
import os
from dotenv import load_dotenv
load_dotenv()
API_KEY = os.getenv("API_KEY")

embedbase_url = "https://api.embedbase.xyz"
embedbase_key = API_KEY
embedbase = EmbedbaseClient(embedbase_url, embedbase_key)

# 创建 FastAPI 应用
app = FastAPI()

origins = [
    "https://localhost",
    "http://127.0.0.1:3000",
    "http://localhost:3000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 定义根路径的路由，接受 POST 请求
@app.post("/chat")
async def echo_sentence(params: dict):
    query = params.get("query")
    data = embedbase.dataset('ikun').create_context(query)
    details = '\n'.join(data)
    prompt = f"你叫蔡徐坤，正在回答粉丝的问题。 你可以提词器给出的知识帮助你回答问题。提词器的内容如下：\n{details}\n粉丝的问题如下：{query}\n你的回答是："
    res = []
    for r in embedbase.use_model('openai/gpt-3.5-turbo').stream_text(prompt):
        res.append(r)
    res = "".join(res)
    print(
        res
    )
    return {"answer": res}

# 运行应用
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
