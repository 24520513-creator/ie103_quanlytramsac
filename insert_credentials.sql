USE EV_Charging_System;
GO

-- Insert demo user credentials (Password: 123456)
INSERT INTO Users.UserCredential (UserID, PasswordHash, PasswordSalt, HashAlgorithm, MFAEnabled, CreatedAt)
VALUES (2, '$2a$12$v3lWXmrEbwjPCKyGDLQrleROYfBfYbdEWPzMW9EnnK0Z.SbKxXmjm', '', 'bcryptjs', 0, GETDATE());
INSERT INTO Users.UserCredential (UserID, PasswordHash, PasswordSalt, HashAlgorithm, MFAEnabled, CreatedAt)
VALUES (3, '$2a$12$9NeCpb7L99gzMgnGXffUhOkIn87CFO7MD7mSsgDSARcAjtlJqxckS', '', 'bcryptjs', 0, GETDATE());
INSERT INTO Users.UserCredential (UserID, PasswordHash, PasswordSalt, HashAlgorithm, MFAEnabled, CreatedAt)
VALUES (4, '$2a$12$FfU05PRrpwTm/hh96gCpDuip7pTBp8kU5yMM2gT/1mc8pLqQcg/jC', '', 'bcryptjs', 0, GETDATE());

-- Insert test user credentials (Password: TestPass123)
INSERT INTO Users.UserCredential (UserID, PasswordHash, PasswordSalt, HashAlgorithm, MFAEnabled, CreatedAt)
VALUES (5, '$2a$12$ZMtjo2QGRS2Hc0s0OsGJou4mXTwvx9mOdzYpEl6gNOhc.Sd8xwt86', '', 'bcryptjs', 0, GETDATE());
INSERT INTO Users.UserCredential (UserID, PasswordHash, PasswordSalt, HashAlgorithm, MFAEnabled, CreatedAt)
VALUES (6, '$2a$12$1kRoliTdyCX.TLcd6J.M6O0YdeLG4Kfyj7bUzrDQ9rc0iMn/SGznq', '', 'bcryptjs', 0, GETDATE());
INSERT INTO Users.UserCredential (UserID, PasswordHash, PasswordSalt, HashAlgorithm, MFAEnabled, CreatedAt)
VALUES (7, '$2a$12$9McHNDvPuxpVhwLPx4qnF.iVE.wVbclXebi4Ru3tnrPVAFNlLHu4y', '', 'bcryptjs', 0, GETDATE());
INSERT INTO Users.UserCredential (UserID, PasswordHash, PasswordSalt, HashAlgorithm, MFAEnabled, CreatedAt)
VALUES (8, '$2a$12$pvbBKOeVeISq1X8wDmOW.uMfT6OvKj93pen13NtoUYlTFWpk8snbC', '', 'bcryptjs', 0, GETDATE());
GO
