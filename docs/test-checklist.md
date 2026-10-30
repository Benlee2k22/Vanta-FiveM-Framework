# First QBCore add-on test session

Use a private FXServer and a test database. Install with the `qbcore-suite` recipe URL in the README.

1. Check the txAdmin console and confirm oxmysql, QBCore and the Vanta resources start without errors.
2. Join and confirm the Vanta loading screen appears during connection and closes when QBCore opens character selection.
3. Create or select a character in QBCore's character selector, choose a spawn, and confirm that the player enters the world.
4. Walk near a Vanta bank or ATM. Confirm the boxed prompt appears, press **E** or **Enter**, scroll through the options, then press **E** or **Enter** to open the bank.
5. Deposit a small amount, withdraw part of it, and check that QBCore cash/bank balances and Vanta transaction history update.
6. Connect a second test player. At a bank branch, send a small transfer using their citizen ID and verify both balances and ledger entries.
7. Press **F1** and confirm QBCore's radial menu opens. Press **F2** and confirm the Vanta radial gives a message when no add-on actions are registered.
8. Confirm the target eye is disabled and the QBCore character, clothing, police, EMS and inventory resources still work.
9. Review both the FXServer console and client F8 console for errors after reconnecting.

The current Vanta QBCore add-on branch installs the upstream QBCore gameplay resources plus Vanta's loading screen, E-interaction UI and banking replacement. Vanta-specific replacements for clothing, police and EMS are not part of this installer build yet.
