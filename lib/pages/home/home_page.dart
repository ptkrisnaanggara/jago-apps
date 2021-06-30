import 'package:flutter/material.dart';
import 'package:jago/theme.dart';
// import 'package:jago/widgets/food_card.dart';
import 'package:jago/widgets/custom_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  Widget buildAppBar() {
    return Container(
      margin: EdgeInsets.only(top: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 100,
            height: 30,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/logo_jago.png',
                ),
              ),
            ),
          ),
          Container(
            width: 50,
            height: 25,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/icon_notification.png',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchBar() {
    return Container(
      width: double.infinity,
      height: 50,
      margin: EdgeInsets.only(top: 30),
      padding: EdgeInsets.symmetric(
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(defaultRadius),
        color: kLightGreyColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Cari Kontak & Tagihan',
            style: greyTextStyle.copyWith(
              fontSize: 14,
              fontWeight: medium,
            ),
          ),
          Container(
            height: 15,
            width: 15,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/icon_search.png',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTabBar() {
    return Container(
      height: 23,
      width: double.infinity,
      margin: EdgeInsets.only(top: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Home',
                style: greenTextStyle.copyWith(
                  fontWeight: semiBold,
                ),
              ),
              Container(
                width: 20,
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  color: kGreenColor,
                ),
              ),
            ],
          ),
          Text(
            'Kantong',
            style: greyTextStyle.copyWith(
              fontWeight: semiBold,
            ),
          ),
          Text(
            'Kontak',
            style: greyTextStyle.copyWith(
              fontWeight: semiBold,
            ),
          ),
          Text(
            'Kartu',
            style: greyTextStyle.copyWith(
              fontWeight: semiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPopularFood() {
    return Container(
      margin: EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   'Shortcut',
          //   style: blackTextStyle.copyWith(
          //     fontSize: 16,
          //     fontWeight: bold,
          //   ),
          // ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shortcut',
                style: blackTextStyle.copyWith(
                  fontWeight: semiBold,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Edit',
                    style: blackTextStyle.copyWith(
                      fontWeight: semiBold,
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      color: kGreenColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          CustomCard(
            name: 'Kantong Utama',
            price: 1000,
            imageUrl: 'assets/wallet.png' ,
          ),
          //   price: 49.999,
          //   imageUrl: 'assets/image_pizza.png',),

          // FoodCard(
          //   name: 'Pizza',
          //   price: 49.999,
          //   imageUrl: 'assets/image_pizza.png',
          // ),
          // FoodCard(
          //   name: 'Hamburger',
          //   price: 59.999,
          //   imageUrl: 'assets/image_hamburger.png',
          // ),
          // FoodCard(
          //   name: 'Double Hot Dog',
          //   price: 34.999,
          //   imageUrl: 'assets/image_hotdog.png',
          // ),
        ],
      ),
    );
  }

  Widget buildBottomNav() {
    return Container(
      width: double.infinity,
      height: 70,
      margin: EdgeInsets.symmetric(
        horizontal: defaultMargin,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27.5),
        color: kLightGreyColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            height: 40,
            width: 99,
            padding: EdgeInsets.symmetric(
              horizontal: 12,
            ),
            decoration: BoxDecoration(
              color: kGreenColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 19,
                  width: 20,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        'assets/icon_home.png',
                      ),
                    ),
                  ),
                ),
                Text(
                  'Home',
                  style: whiteTextStyle.copyWith(
                    fontWeight: bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 18,
            height: 19,
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage(
                  'assets/icon_notification.png',
                ),
              ),
            ),
          ),
          Container(
            width: 20,
            height: 18,
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage(
                  'assets/icon_favorite.png',
                ),
              ),
            ),
          ),
          Container(
            width: 17,
            height: 20,
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage(
                  'assets/icon_profile.png',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: buildBottomNav(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: defaultMargin,
        ),
        children: [
          buildAppBar(),
          buildSearchBar(),
          buildTabBar(),
          buildPopularFood(),
          SizedBox(
            height: 140,
          ),
        ],
      ),
    );
  }
}
