# First test session

Use a private FXServer first. Install oxmysql, import the complete `sql/vanta.sql`, and ensure resources in the order shown in the README. Make sure server console reports the core and modules started without errors.

1. Connect with one player. Confirm the saved player record appears in `vanta_players` and the inventory row appears in `vanta_inventories`.
2. Use `/giveitem 1 water_bottle 3` and `/giveitem 1 sandwich 2`. Press **I**, use one item, close and reopen; verify the quantity and metadata persist after reconnecting.
3. At a configured ATM, deposit $100, then withdraw $50. Confirm the balance updates and `vanta_bank_transactions` receives entries.
4. Connect a second player. At a bank branch transfer a small amount using the second player's citizen ID. Confirm both balances and history entries update.
5. Run `/setjob 1 police 1`. At Mission Row, scroll to **Clock in / out**, press **E**, then open F1. Test backup alerts with both players online. Cuff and escort require the target to be within a few metres; cuff them before escorting.
6. Test uncuff, duty toggling and invalid cases: off-duty police actions, distant targets, a non-police player, insufficient bank balance, excessive bank amount, and transfers from an ATM.
7. Run `/setjob 1 ambulance 1`, clock EMS on at a hospital, use **Treat nearby** on the second player, and check in at reception as a regular player. Verify the $500 charge and health change.
8. Disconnect/reconnect and verify position, money, job and inventory reload.

The included hospital revive is a simple base-game loop. It should be connected to the death/injury resource you choose before you rely on it as a production medical system.
