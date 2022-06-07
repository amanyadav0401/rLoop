import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Signer } from "ethers";
import { ethers, network } from "hardhat";
import { RLoopStaking, RLoopStaking__factory, Token1, Token1__factory } from "../typechain"
import { expandTo18Decimals } from "./utilities/utilities";
import {expect} from "chai";
import { sign } from "crypto";

describe("RLoop Testing",()=>{
   let owner : SignerWithAddress;
   let signers : SignerWithAddress[]; 
   let token : Token1;
   let staking : RLoopStaking;

   beforeEach(async()=>{
       signers = await ethers.getSigners();
       owner = signers[0];
       token = await new Token1__factory(owner).deploy("Yato","YTC",1000000);
       staking = await new RLoopStaking__factory(owner).deploy(token.address);
       await token.connect(owner).transfer(staking.address,expandTo18Decimals(10000));
       await token.connect(owner).transfer(signers[1].address,expandTo18Decimals(1000));
       await token.connect(owner).transfer(signers[2].address,expandTo18Decimals(1000));
       await token.connect(owner).transfer(signers[3].address,expandTo18Decimals(1000));
       await staking.connect(owner).setTimeRewardPercent(2592000,2000);  
       await token.connect(signers[1]).approve(staking.address,expandTo18Decimals(1000));
       await staking.connect(signers[1]).stake(2592000,expandTo18Decimals(100));

   })

   describe("RLoopTest", async()=>{

    it("Deposit stake",async()=>{
        await token.connect(signers[1]).approve(staking.address,expandTo18Decimals(1000));
        let error = "Time not specified!";
        await staking.connect(signers[1]).stake(2592000,expandTo18Decimals(100));
        await staking.connect(signers[1]).stake(2592000,expandTo18Decimals(80));
        let transaction = await staking.connect(signers[1]).checkTransaction(2);
        console.log("Transaction History:  "+transaction);
    })

    it.only("Claimable Reward",async()=>{
        await network.provider.send("evm_increaseTime", [3456000]);
        await network.provider.send("evm_mine"); 
        await staking.connect(signers[1]).stake(2592000,expandTo18Decimals(80));
        await network.provider.send("evm_increaseTime", [3456000]);
        await network.provider.send("evm_mine"); 
        console.log("Claimable Rewards 1:   "+await staking.connect(signers[1]).claimableReward(1));
        console.log("Claimable Rewards 2:   "+await staking.connect(signers[1]).claimableReward(2));
    })
    it("Claim Rewards before and after stake time",async()=>{
        await network.provider.send("evm_increaseTime", [3456000]);
        await network.provider.send("evm_mine"); 
        console.log("Old balance in tokens:  "+await token.balanceOf(signers[1].address));
        await staking.connect(signers[1]).claimReward(1);
        console.log("New balance in tokens:  "+await token.balanceOf(signers[1].address));
        console.log("Transaction history:  "+await staking.connect(signers[1]).checkTransaction(1));
    })
    it("Changing investment time and reward percent", async()=>{
        await staking.connect(owner).setTimeRewardPercent(5184000,30);
    })

   })




})
