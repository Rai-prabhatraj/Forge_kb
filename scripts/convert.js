const bigInt = require('big-integer');

const hexString = "bce80fd2cd006d3e910c844a8c43ccda335abad5ea59609a054f13687726c32e";
const integer = bigInt(hexString, 16);

console.log(integer.toString());
