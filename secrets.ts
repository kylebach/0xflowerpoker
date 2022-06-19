require('dotenv').config();

export default {
  rpc: process.env.RPC || 'https://polygon-rpc.com',
  account: process.env.ACCOUNT || '',
};
