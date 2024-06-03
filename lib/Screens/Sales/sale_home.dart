import 'package:flutter/material.dart';
import '../../components/header.dart';
import '../../components/menu.dart';
import '../../constants.dart';
import 'package:flutter/src/material/search_anchor.dart' as material_search;
import 'package:flutter_auth/Screens/Home/search_bar.dart' as custom_search;

class SalesHome extends StatelessWidget {
  
  const SalesHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Odoo App',
      theme: ThemeData(
        fontFamily: "Cairo",
        scaffoldBackgroundColor: kPrimaryLightColor,
        textTheme: Theme.of(context).textTheme.apply(displayColor: kPrimaryColor),
      ),
      home: const SalesHomeScreen(),
    );
  }
}

class SalesHomeScreen extends StatelessWidget {
  const SalesHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size * 0.5; //this gonna give us total height and with of our device

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Header(size: size),
          const Body(title: "Sales Menu")
        ],
      ),
    );
  }
}

class Body extends StatelessWidget {
  const Body({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String? title;

  @override
  Widget build(BuildContext context) {
    final List<Map> menus = [
      {'name':'Quotation', 'route':'/saleOrder/draft', 'icon': Icons.public, 'iconColor': Colors.red[300]},
      {'name':'Sale Order','route':'/saleOrder/confirmed', 'icon': Icons.shopping_basket, 'iconColor': Colors.orange[300]},
      {'name':'Customers', 'route':'/partner/customer', 'icon': Icons.account_balance, 'iconColor': Colors.purple[300]},
      {'name':'Delivery','route':'/picking/delivery', 'icon': Icons.warehouse, 'iconColor': Colors.blue[300]},
      {'name':'Invoices','route':'/invoice/customer', 'icon': Icons.money, 'iconColor': Colors.green[300]},
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title ?? '',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const material_search.SearchBar(), // Use custom_search alias here
            Expanded(
              child: GridMenu(menus: menus),
            ),
          ],
        ),
      ),
    );
  }
}
