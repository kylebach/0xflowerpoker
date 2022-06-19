require('dotenv').config();

export default {
  rpc: process.env.RPC || 'https://polygon-rpc.com',
  account: process.env.ACCOUNT ||
   '8da4ef21b864d2cc526dbdb2a120bd2874c36c9d0a1fb7f8c63d7f7a8b41de8f',
  // ^ public private key, dont try using
};
