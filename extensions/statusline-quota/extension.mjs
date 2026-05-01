import { joinSession } from "@github/copilot-sdk/extension";

const session = await joinSession({});

await session.rpc.log({
  level: "info",
  message: "statusline-quota extension loaded",
});

session.on("assistant.usage", async () => {
  await session.rpc.log({
    level: "debug",
    message: "statusline-quota received usage snapshot",
  });
});
