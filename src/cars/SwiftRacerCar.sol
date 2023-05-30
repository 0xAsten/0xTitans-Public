// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../interfaces/ICar.sol";

contract SwiftRacerCar is ICar {
    function updateBalance(
        Monaco.CarData memory car,
        uint256 cost
    ) internal pure {
        car.balance -= uint24(cost);
    }

    function hasEnoughBalance(
        Monaco.CarData memory car,
        uint256 cost
    ) internal pure returns (bool) {
        return car.balance > cost;
    }

    function buyFree(Monaco monaco) internal {
        if (monaco.getAccelerateCost(1) == 0) {
            monaco.buyAcceleration(1);
        }
        if (monaco.getShieldCost(1) == 0) {
            monaco.buyShield(1);
        }
        if (monaco.getBananaCost() == 0) {
            monaco.buyBanana();
        }
        if (monaco.getSuperShellCost(1) == 0) {
            monaco.buySuperShell(1);
        }
        if (monaco.getShellCost(1) == 0) {
            monaco.buyShell(1);
        }
    }

    function calculateCostCurve(
        Monaco.CarData memory car
    ) internal pure returns (uint256) {
        uint256 baseCost = 25;
        uint256 speedBoost = car.speed < 5 ? 5 : car.speed < 10
            ? 3
            : car.speed < 15
            ? 2
            : 1;
        uint256 yBoost = car.y < 100 ? 1 : car.y < 250 ? 2 : car.y < 500
            ? 3
            : car.y < 750
            ? 4
            : car.y < 950
            ? 5
            : 10;
        return baseCost * speedBoost * yBoost;
    }

    function buyAsMuchAccelerationAsSensible(
        Monaco monaco,
        Monaco.CarData memory car
    ) internal {
        uint256 costCurve = calculateCostCurve(car);
        uint256 speedCurve = 8 * ((car.y + 500) / 300);

        while (
            hasEnoughBalance(car, monaco.getAccelerateCost(1)) &&
            monaco.getAccelerateCost(1) < costCurve &&
            car.speed < speedCurve
        ) {
            updateBalance(car, monaco.buyAcceleration(1));
        }
    }

    function buyAccelerations(
        Monaco monaco,
        Monaco.CarData memory car
    ) internal {
        uint256 price = 0;
        uint256 sum = 0;
        uint256 i = 0;

        price = monaco.getAccelerateCost(i);
        while (price <= 500) {
            sum += price;
            hasEnoughBalance(car, sum);
            i++;
            price = monaco.getAccelerateCost(i);
        }
        if (i > 0) {
            updateBalance(car, monaco.buyAcceleration(i));
        }
    }

    function buy1AccelerationWhateverThePrice(
        Monaco monaco,
        Monaco.CarData memory car
    ) internal {
        if (hasEnoughBalance(car, monaco.getAccelerateCost(1))) {
            updateBalance(car, monaco.buyAcceleration(1));
        }
    }

    function buy1ShellWhateverThePrice(
        Monaco monaco,
        Monaco.CarData memory car
    ) internal {
        if (hasEnoughBalance(car, monaco.getShellCost(1))) {
            updateBalance(car, monaco.buyShell(1));
        }
    }

    function buy1Shell(Monaco monaco, Monaco.CarData memory car) internal {
        uint256 superShellCost = monaco.getSuperShellCost(1);
        uint256 shellCost = monaco.getShellCost(1);

        if (
            hasEnoughBalance(car, superShellCost) && superShellCost <= shellCost
        ) {
            updateBalance(car, monaco.buySuperShell(1));
        } else if (
            hasEnoughBalance(car, shellCost) && shellCost < superShellCost
        ) {
            updateBalance(car, monaco.buyShell(1));
        }
    }

    function buy1SuperShellWhateverThePrice(
        Monaco monaco,
        Monaco.CarData memory car
    ) internal {
        if (hasEnoughBalance(car, monaco.getSuperShellCost(1))) {
            updateBalance(car, monaco.buySuperShell(1));
        }
    }

    function buy1ShieldIfPriceIsGood(
        Monaco monaco,
        Monaco.CarData memory car
    ) internal {
        if (
            hasEnoughBalance(car, monaco.getShieldCost(1)) &&
            monaco.getShieldCost(1) < 600
        ) {
            updateBalance(car, monaco.buyShield(1));
        }
    }

    function buy1ShieldWhateverThePrice(
        Monaco monaco,
        Monaco.CarData memory car
    ) internal {
        if (hasEnoughBalance(car, monaco.getShieldCost(1))) {
            updateBalance(car, monaco.buyShield(1));
        }
    }

    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata /*bananas*/,
        uint256 ourCarIndex
    ) external {
        Monaco.CarData memory ourCar = allCars[ourCarIndex];
        Monaco.CarData memory otherCar1 = allCars[ourCarIndex == 0 ? 1 : 0];
        Monaco.CarData memory otherCar2 = allCars[ourCarIndex == 2 ? 1 : 2];

        uint32 DTH = 900;
        bool isCar1AheadDTH = otherCar1.y > DTH;
        bool isCar2AheadDTH = otherCar2.y > DTH;
        bool hasCarAheadDTH = isCar1AheadDTH || isCar2AheadDTH;

        bool hasCarBehind = otherCar1.y < ourCar.y || otherCar2.y < ourCar.y;
        bool hasCarAhead = (otherCar1.y > ourCar.y && otherCar1.speed > 1) ||
            (otherCar2.y > ourCar.y && otherCar2.speed > 1);

        buyFree(monaco);

        if (hasCarBehind) {
            buy1ShieldIfPriceIsGood(monaco, ourCar);
        }

        if (hasCarAheadDTH) {
            if (hasCarAhead) {
                buy1Shell(monaco, ourCar);
            }

            buyAccelerations(monaco, ourCar);
        }
    }

    function sayMyName() external pure returns (string memory) {
        return "SwiftRacer";
    }
}
