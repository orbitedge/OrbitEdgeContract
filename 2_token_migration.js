const Token = artifacts.require("Token");
const CrowdSale = artifacts.require("CrowdFunding");
module.exports = function (deployer) {
    // Token.deployed().then(token=>{
    //     console.log(token.address);
    // })
    let name = "Orbit Edge";
    let symbol = "OEDGE";
    deployer.deploy(Token,name,symbol).then(()=>{
        console.log(Token.address);
        let role = '0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6'
        return deployer.deploy(CrowdSale,Token.address,false,'0x2528c50Cacf05CABF55488d72802B44fA5b75Be9',1).then(async ()=>{

            let token =  await Token.deployed();
            await token.addMinter(CrowdSale.address);
        })
    });
};
