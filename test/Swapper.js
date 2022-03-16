const {expect} = require('chai');
const provider = waffle.provider;

describe("Swapper", ()=> {
  let Swapper,
      swapper,
      router,
      dai,
      owner,
      user;

  // router address
  const UNISWAP_ROUTER = "0xf164fC0Ec4E93095b804a4795bBe1e041497b92a";
  // token addresses
  const DAI_ADDRESS = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
  const LINK_ADDRESS = "0x514910771AF9Ca656af840dff83E8264EcF986CA";
  const UNI_ADDRESS = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984";
  // ether prices in different tokens
  let PriceInDai = ethers.utils.parseEther("2400");
  let PriceInLink = ethers.utils.parseEther("150");
  let PriceInUni = ethers.utils.parseEther("200");


  before(async ()=> {
    Swapper = await ethers.getContractFactory("SwapperTest"); 
    router = await ethers.getContractAt("IUniswapV2Router01", UNISWAP_ROUTER);
    dai = await ethers.getContractAt("IERC20", DAI_ADDRESS);
    link = await ethers.getContractAt("IERC20", LINK_ADDRESS);
    uni = await ethers.getContractAt("IERC20", UNI_ADDRESS);
  });

  beforeEach(async ()=> {
    [owner, user] = await ethers.getSigners();
    swapper = await upgrades.deployProxy(Swapper, [router.address, 1, user.address]);
  });

  describe("Deployment", ()=> {
    it("Should be initialized correctly", async ()=> {
      expect(await swapper.swapRouter())
      .to
      .equal(router.address);
    });
  });

  describe("Private functions assertions", ()=>{
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

    it("Should retrieve if fee charge fails", async()=> {
      await expect(swapper.chargeFee(ethers.utils.parseEther("1")))
      .to
      .be
      .revertedWith("ETH was not sent to recipient");
    });
  });

  describe("swapMultipleTokens assertions", ()=> {
    let addresses = [DAI_ADDRESS, LINK_ADDRESS, UNI_ADDRESS];
    let prices = [PriceInDai, PriceInLink, PriceInUni];
    let percents = [20, 50, 30];

    it("Should not allow to swap tokens if the arguments sizes are invalid", async()=> {
      await expect(swapper.swapMultipleTokens(
        [LINK_ADDRESS, DAI_ADDRESS],
        [20, 40, 40],
        [PriceInLink]
      ))
      .to
      .be
      .revertedWith("Arguments arrays must have equal size");
    });

    it("Should not allow to swap tokens if the sum of the specified percents exceeds 100%", async()=> {
      await expect(swapper.swapMultipleTokens(
        [LINK_ADDRESS, DAI_ADDRESS],
        [50, 70],
        [PriceInLink, PriceInDai]
      ))
      .to
      .be
      .revertedWith("The sum of the percents cannot exceeds 100");
    })

    it("Should allow to swap all the tokens", async ()=> {
      await swapper.swapMultipleTokens(
        addresses,
        percents,
        prices,
        {value: ethers.utils.parseEther("10")}
      );

      expect(await dai.balanceOf(owner.address))
      .to
      .above(PriceInDai.mul(2));
      expect(await link.balanceOf(owner.address))
      .to
      .above(PriceInLink.mul(5));
      expect(await uni.balanceOf(owner.address))
      .to
      .above(PriceInUni.mul(3));

    });

    it("Should pay the recipient the correct fee per transaction", async ()=> {
      let prevBalance = await provider.getBalance(user.address);

      await swapper.swapMultipleTokens(
        [UNI_ADDRESS],
        [100],
        [PriceInUni],
        {value: ethers.utils.parseEther("1")}
      );

      expect(await provider.getBalance(user.address))
      .to
      .equal(prevBalance.add(ethers.utils.parseEther("1").mul("1").div("1000")));
    });

    it("The contract should not store any funds", async()=> {
      await swapper.swapMultipleTokens(
        [LINK_ADDRESS],
        [100],
        [PriceInLink],
        {value: ethers.utils.parseEther("1")}
      );

      expect(await provider.getBalance(swapper.address))
      .to
      .equal(0);
    });
  });

  describe("Set fee and recipient assertions", ()=> {
    it("Should allow only the admin to set the fee", async()=> {
      await expect(swapper.connect(user).setFee(20))
      .to
      .be
      .revertedWith("");

      await swapper.setFee(50);

      expect(await swapper.fee())
      .to
      .equal(50);
    })

    it("Should only allow the admin to set the recipient", async()=> {
      await expect(swapper.connect(user).setRecipient(dai.address))
      .to
      .be
      .revertedWith("");

      await swapper.setRecipient(owner.address);

      expect(await swapper.recipient())
      .to
      .equal(owner.address);
    });
  })

});
