import { writeFile } from "node:fs/promises";
import { join } from "node:path";
import { homedir } from "node:os";
import { joinSession } from "@github/copilot-sdk/extension";

const session = await joinSession({});
const outputPath = join(homedir(), ".copilot", "premium-quota.json");

session.on("assistant.usage", async (event) => {
    const snapshots = event.data?.quotaSnapshots;
    if (!snapshots) return;

    const premium = snapshots["premium_interactions"];
    if (!premium) return;

    await writeFile(
        outputPath,
        JSON.stringify({
            entitlementRequests: premium.entitlementRequests,
            usedRequests: premium.usedRequests,
            remainingPercentage: premium.remainingPercentage,
            overage: premium.overage,
            isUnlimitedEntitlement: premium.isUnlimitedEntitlement,
            resetDate: premium.resetDate,
            updatedAt: new Date().toISOString(),
        }),
        "utf-8",
    );
});
