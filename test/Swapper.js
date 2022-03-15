const {expect} = require('chai');
const provider = waffle.provider;

describe("Swapper", ()=> {
  let Swapper,
      swapper,
      router,
      dai,
      owner,
      user;

  const UNISWAP_ROUTER = "0xf164fC0Ec4E93095b804a4795bBe1e041497b92a";
  const DAI_ADDRESS = "0x6B175474E89094C44Da98b954EedeAC495271d0F";

  before(async ()=> {
    Swapper = await ethers.getContractFactory("SwapperTest"); 
    router = await ethers.getContractAt("IUniswapV2Router01", UNISWAP_ROUTER);
    dai = await ethers.getContractAt("IERC20", DAI_ADDRESS);
  });

  beforeEach(async ()=> {
    [owner, user] = await ethers.getSigners();
    swapper = await upgrades.deployProxy(Swapper, [router.address]);
  });

  describe("Deployment", ()=> {
    it("Should be initialized correctly", async ()=> {
      expect(await swapper.swapRouter())
      .to
      .equal(router.address);
    });
  });

  describe("SwapETHforTokens assertions", ()=>{
    let ethSent = ethers.utils.parseEther("1");
    let minTokenExpected = ethers.utils.parseEther("2300");

    it("Should swap the specified ether", async ()=> {
      expect(await dai.balanceOf(owner.address))
      .to
      .equal(0);
      await swapper.swapETHForTokens(ethSent, minTokenExpected, dai.address, {value: ethSent});
      expect(await dai.balanceOf(owner.address))
      .to
      .above(minTokenExpected);

    });

  });

});