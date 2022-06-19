require('dotenv').config();

let localrpc = 'https://polygon-rpc.com';
let localacc =
    '8da4ef21b864d2cc526dbdb2a120bd2874c36c9d0a1fb7f8c63d7f7a8b41de8f';
if (process.env.RPC !== undefined) {
  localrpc = process.env.RPC;
}
if ( process.env.ACCOUNT !== undefined) {
  localacc = process.env.ACCOUNT;
}
export default {
  rpc: localrpc,
  account: localacc,
};
