const bcrypt = require('bcryptjs');

const passwords = ['Admin@123', 'Manager@123', 'Customer@123'];

async function main() {
    console.log('=== EV Charging System - Password Hash Generator ===\n');
    console.log('Algorithm: bcryptjs (salt rounds = 12)\n');

    for (const pwd of passwords) {
        const salt = bcrypt.genSaltSync(12);
        const hash = bcrypt.hashSync(pwd, salt);
        console.log(`${pwd}: ${hash}`);
    }

    console.log('\n=== Copy the hashes above into your SQL seed script ===');
    console.log('SQL format:');
    console.log(`N'<hash>'`);
}

main().catch(console.error);
