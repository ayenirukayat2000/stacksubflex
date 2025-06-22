# stacksubflex

**SubChainFlex** is a Clarity smart contract for the Stacks blockchain that implements an enhanced micro-payment subscription protocol with admin controls.

## Features

- **Subscription Plans:** Providers can create, update, pause/resume, and transfer ownership of subscription plans.
- **Subscriptions:** Users can subscribe, process recurring payments, and cancel their subscriptions.
- **Admin Controls:** The contract admin can remove plans, remove subscriptions, and transfer admin rights.
- **Payment Handling:** Secure transfer of STX for subscription fees.

## Contract Overview

- **Contract File:** [`contracts/stacksubflex.clar`](contracts/stacksubflex.clar)
- **Admin:** The deployer is set as the initial admin and can transfer admin rights.
- **Plans:** Each plan has a provider, fee, interval, metadata, and active status.
- **Subscriptions:** Each subscription tracks the subscriber, plan, start block, next payment block, and active status.


