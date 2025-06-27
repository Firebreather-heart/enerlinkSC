// This script runs in the Remix JavaScript VM.
// Right-click this file in the Remix explorer and select "Run".

(async () => {
    try {
        console.log('Starting deployment and client interaction script...');

        // --- 1. DEPLOYMENT ---
        console.log('Deploying MockUSDC contract...');
        const MockUSDCArtifact = await remix.call('compiler', 'getCompilationResult', {
            path: 'contracts/mocks/MockUSDC.sol',
            name: 'MockUSDC'
        });
        const MockUSDCFactory = new ethers.ContractFactory(
            MockUSDCArtifact.abi,
            MockUSDCArtifact.evm.bytecode.object,
            (await ethers.getSigners())[0]
        );
        const mockUSDC = await MockUSDCFactory.deploy();
        await mockUSDC.deployed();
        console.log(`MockUSDC deployed at: ${mockUSDC.address}`);

        console.log('Deploying PaymentContract...');
        const PaymentContractArtifact = await remix.call('compiler', 'getCompilationResult', {
             path: 'contracts/PaymentContract.sol',
             name: 'PaymentContract'
        });
        const PaymentContractFactory = new ethers.ContractFactory(
             PaymentContractArtifact.abi,
             PaymentContractArtifact.evm.bytecode.object,
            (await ethers.getSigners())[0]
        );
        const paymentContract = await PaymentContractFactory.deploy(mockUSDC.address);
        await paymentContract.deployed();
        console.log(`PaymentContract deployed at: ${paymentContract.address}`);

        // --- 2. SETUP EVENT LISTENER ---
        console.log('\nSetting up event listener for PaymentReceived...');
        
        paymentContract.on('PaymentReceived', (user, amount, timestamp, isUSDC) => {
            console.log('\n✅✅✅ Event Detected! ✅✅✅');
            console.log(`   -> User: ${user}`);
            const formattedAmount = ethers.utils.formatUnits(amount, isUSDC ? 18 : 'ether'); // Note: MockUSDC has 18 decimals
            console.log(`   -> Amount: ${formattedAmount} ${isUSDC ? 'USDC' : 'ETH'}`);
            console.log('   -> Backend: Triggering user activation logic...');
            console.log('------------------------------------');
        });

        // --- 3. SIMULATE A USER TRANSACTION ---
        console.log('\nSimulating a user paying 0.05 ETH...');
        const userSigner = (await ethers.getSigners())[1]; // Use a different account as the user
        const tx = await paymentContract.connect(userSigner).payWithNative({ value: ethers.utils.parseEther("0.05") });
        await tx.wait();
        console.log('Transaction sent! The listener above should have detected the event.');
        console.log('Script finished. The listener will remain active.');

    } catch (e) {
        console.error('An error occurred:', e.message);
    }
})();