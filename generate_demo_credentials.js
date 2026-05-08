// Script to generate password hashes for demo users
const bcrypt = require('./backend/node_modules/bcryptjs');

// Demo users with password '123456'
const demoUsers = [
    { username: 'admin', userID: 2, password: '123456' },
    { username: 'operator', userID: 3, password: '123456' },
    { username: 'customer', userID: 4, password: '123456' },
];

async function generateHashes() {
    console.log('-- SQL Script to insert demo user credentials');
    console.log('-- Password: 123456 for all demo accounts\n');
    console.log('USE EV_Charging_System;');
    console.log('GO\n');
    console.log('-- Insert demo user credentials\n');
    
    for (const user of demoUsers) {
        const saltRounds = 12;
        const hash = await bcrypt.hash(user.password, saltRounds);
        
        const sqlInsert = `INSERT INTO Users.UserCredential (UserID, PasswordHash, PasswordSalt, HashAlgorithm, MFAEnabled, CreatedAt)
VALUES (${user.userID}, '${hash}', '', 'bcryptjs', 0, GETDATE());`;
        
        console.log(sqlInsert);
    }
    
    console.log('\nGO');
    console.log('\n-- Also insert test user credentials if not already done\n');
    
    const testUsers = [
        { username: 'nguyenthimai', userID: 5, password: 'TestPass123' },
        { username: 'tranvannam', userID: 6, password: 'TestPass123' },
        { username: 'lethihuong', userID: 7, password: 'TestPass123' },
        { username: 'phamvantuan', userID: 8, password: 'TestPass123' },
    ];
    
    for (const user of testUsers) {
        const saltRounds = 12;
        const hash = await bcrypt.hash(user.password, saltRounds);
        
        const sqlInsert = `INSERT INTO Users.UserCredential (UserID, PasswordHash, PasswordSalt, HashAlgorithm, MFAEnabled, CreatedAt)
VALUES (${user.userID}, '${hash}', '', 'bcryptjs', 0, GETDATE());`;
        
        console.log(sqlInsert);
    }
    
    console.log('\nGO');
}

generateHashes().catch(console.error);
