# First test session

Use a private FXServer and a test database. Install the recipe from the URL in the README, and make sure the txAdmin console reports every resource started without errors.

1. Join and confirm the Vanta loading screen shows the progress bar and tips. Click **Enable ambient music** and confirm the toggle turns on; turn it off again.
2. Confirm the character selector appears instead of the default world spawn. Create a character and choose a spawn point. Confirm you enter the game at the selected point.
3. Disconnect and reconnect. Select the same character and choose **Last location**; confirm it returns to the saved position.
4. Create a second character. Assign police to one character and ambulance to the other; check that each character has its own money, job, inventory and position.
5. Select **Delete** for a test character and cancel once. Reopen the prompt, confirm deletion, then check that only that character's data was removed.
6. At a configured clothing store, approach until the boxed HUD prompt appears. Press **E**, select **Browse clothing**, then use the clothing panel to change a component and texture. Save the outfit and confirm the configured cash charge.
7. At a configured wardrobe, use the HUD prompt and press **E** to open the wardrobe. Wear the outfit, then reconnect and verify that the current appearance persists.
8. Press **F1** after spawning and confirm the radial quick actions still open independently of the E interaction menu.
9. Use `/giveitem 1 water_bottle 3` and `/giveitem 1 sandwich 2`. Press **I**, use one item, close and reopen; verify quantity and metadata persist.
10. At a configured ATM, deposit $100, then withdraw $50. Confirm balances update and `vanta_bank_transactions` receives entries.
11. Connect a second player. At a bank branch, transfer a small amount using the second player's citizen ID. Confirm both balances and transaction history.
12. Run `/setjob 1 police 1`, clock in at Mission Row, then test cuff, uncuff, escort and backup with both players. Verify off-duty actions, distant targets, non-police actions and uncuffed escort are rejected.
13. Run `/setjob 1 ambulance 1`, clock EMS on at a hospital, use **Treat nearby** on the second player, and check in at reception as a regular player. Verify the $500 charge and health change.
14. Disconnect/reconnect and confirm position, money, job, inventory and clothing load for the selected character.

The included hospital revive is a simple base-game loop. Connect it to the death/injury resource you choose before relying on it as a production medical system.
