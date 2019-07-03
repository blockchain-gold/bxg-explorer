
const lastPowBlock = 200;
const avgBlockTime = 60;
const blocksPerDay = (24 * 60 * 60) / avgBlockTime;
const blocksPerWeek = blocksPerDay * 7;
const blocksPerMonth = (blocksPerDay * 365.25) / 12;
const blocksPerYear = blocksPerDay * 365.25;
const mncoins = 5000.0;

const specs =
  [
    { start: 0, end: 43200, reward: 2, pos: 0.50, node: 1.50, collateral: 5000 },
    { start: 43201, end: 86400, reward: 10, pos: 2.50, node: 7.50, collateral: 5000 },
    { start: 86401, end: 129600, reward: 2, pos: 0.50, node: 1.50, collateral: 5000 },
    { start: 129601, end: 172800, reward: 5, pos: 0.60, node: 4.40, collateral: 5000 },
    { start: 172801, end: 216000, reward: 7, pos: 0.84, node: 6.16, collateral: 5000 },
    { start: 216001, end: 259200, reward: 10, pos: 1.20, node: 8.80, collateral: 5000 },
    { start: 259201, end: 302400, reward: 25, pos: 3.00, node: 22.00, collateral: 25000 },
    { start: 302401, end: 648000, reward: 35, pos: 4.20, node: 30.80, collateral: 25000 },
    { start: 648001, end: 1036800, reward: 33, pos: 3.96, node: 29.04, collateral: 50000 },
    { start: 1036801, end: 1296000, reward: 31, pos: 3.72, node: 27.28, collateral: 50000 },
    { start: 1296001, end: 1555200, reward: 29, pos: 3.48, node: 25.52, collateral: 50000 },
    { start: 1555201, end: 1814400, reward: 27, pos: 3.24, node: 23.76, collateral: 50000 },
    { start: 1814401, end: 2073600, reward: 25, pos: 3.00, node: 22.00, collateral: 50000 },
    { start: 2073601, end: 2332800, reward: 23, pos: 2.76, node: 20.24, collateral: 50000 },
    { start: 2332801, end: 2592000, reward: 21, pos: 2.52, node: 18.48, collateral: 50000 },
    { start: 2592001, end: 2851200, reward: 19, pos: 2.28, node: 16.72, collateral: 50000 },
    { start: 2851200, end: 3110400, reward: 17, pos: 2.04, node: 14.96, collateral: 50000 },
    { start: 3110401, end: 3369600, reward: 15, pos: 1.80, node: 13.20, collateral: 50000 },
    { start: 3369601, end: 3628800, reward: 13, pos: 1.56, node: 11.44, collateral: 50000 },
    { start: 3628801, end: 3888000, reward: 11, pos: 1.32, node: 9.68, collateral: 50000 },
    { start: 3888001, end: 4147200, reward: 9, pos: 1.08, node: 7.92, collateral: 50000 },
    { start: 4147201, end: 4406400, reward: 8, pos: 0.96, node: 7.04, collateral: 50000 },
    { start: 4406401, end: 4665600, reward: 7, pos: 0.84, node: 6.16, collateral: 50000 },
    { start: 4665601, end: 4924800, reward: 6, pos: 0.72, node: 5.28, collateral: 50000 },
    { start: 4924801, end: 5184000, reward: 5, pos: 0.60, node: 4.40, collateral: 50000 },
    { start: 5184001, end: 20894800, reward: 2, pos: 0.24, node: 1.76, collateral: 50000 }
  ];

const getMnCoins = blockHeight => specs.find(x => blockHeight >= x.start && blockHeight <= x.end).collateral;

const getMnBlocksPerDay = mns => blocksPerDay / mns;

const getMnBlocksPerWeek = mns => getMnBlocksPerDay(mns) * (365.25 / 52);

const getMnBlocksPerMonth = mns => getMnBlocksPerDay(mns) * (365.25 / 12);

const getMnBlocksPerYear = mns => getMnBlocksPerDay(mns) * 365.25;

const getSubsidy = (blockHeight = 1) => specs.find(x => blockHeight >= x.start && blockHeight <= x.end).reward;

const getMnSubsidy = (blockHeight = 1) => specs.find(x => blockHeight >= x.start && blockHeight <= x.end).node;

const getRoi = (subsidy, mns) => ((getMnBlocksPerYear(mns) * subsidy) / mncoins) * 100.0;

const isAddress = s => typeof (s) === 'string' && s.length === 34;

const isBlock = s => !isNaN(s) || (typeof (s) === 'string');

const isPoS = b => !!b && b.height > lastPowBlock; // > 182700

const isTx = s => typeof (s) === 'string' && s.length === 64;

/**
 * How we identify if a raw transaction is Proof Of Stake & Masternode reward
 * @param {String} rpctx The transaction hash string.
 */
const isRewardRawTransaction = rpctx =>
  rpctx.vin.length == 1 &&
  rpctx.vout.length == 3 &&
  // First vout is always in this format
  rpctx.vout[0].value == 0.0 &&
  rpctx.vout[0].n == 0 &&
  rpctx.vout[0].scriptPubKey &&
  rpctx.vout[0].scriptPubKey.type == "nonstandard";

module.exports =
  {
    avgBlockTime,
    blocksPerDay,
    blocksPerMonth,
    blocksPerWeek,
    blocksPerYear,
    getMnBlocksPerDay,
    getMnBlocksPerMonth,
    getMnBlocksPerWeek,
    getMnBlocksPerYear,
    getMnCoins,
    getMnSubsidy,
    getSubsidy,
    getRoi,
    isAddress,
    isBlock,
    isPoS,
    isTx,
    isRewardRawTransaction,
    lastPowBlock,
    mncoins
  };
