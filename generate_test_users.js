// Script to generate password hashes for test users
const bcrypt = require('./backend/node_modules/bcryptjs');

// Test users with passwords
const testUsers = [
    { username: 'nguyenthimai', email: 'mai.nguyen@email.com', password: 'TestPass123', userID: 2 },
    { username: 'tranvannam', email: 'nam.tran@email.com', password: 'TestPass123', userID: 3 },
    { username: 'lethihuong', email: 'huong.le@email.com', password: 'TestPass123', userID: 4 },
    { username: 'phamvantuan', email: 'tuan.pham@email.com', password: 'TestPass123', userID: 5 },
];

async function generateHashes() {
    console.log('-- SQL Script to insert test user credentials\n');
    console.log('USE EV_Charging_System;');
    console.log('GO\n');
    console.log('-- Insert test user credentials');
    
    for (const user of testUsers) {
        const saltRounds = 12;
        const hash = await bcrypt.hash(user.password, saltRounds);
        
        const sqlInsert = `INSERT INTO Users.UserCredential (UserID, PasswordHash, PasswordSalt, HashAlgorithm, MFAEnabled, CreatedAt)
VALUES (${user.userID}, '${hash}', '', 'bcryptjs', 0, GETDATE());`;
        
        console.log(sqlInsert);
    }
    
    console.log('\nGO');
}

generateHashes();
