import 'dart:convert';
import 'package:carner/Article.dart';
import 'package:carner/Constant.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Liste extends StatefulWidget {
  const Liste({super.key});

  @override
  State<Liste> createState() => _ListeState();
}

class _ListeState extends State<Liste> {
  List<Article> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_articles.isEmpty) {
      return const Center(child: Text('Aucun article dans votre liste'));
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _dialogBuilder(context),
        child: const Icon(Icons.delete),
      ),
      body: ListView.builder(
        itemCount: _articles.length,
        itemBuilder: (context, index) {
          final article = _articles[index];
          return GestureDetector(
              onTap: () {
                _markArticle(article.id, article.okay!);
                setState(() {
                  print(article.okay);
                  article.okay = !article.okay!;
                  print(article.okay);
                  print("ici");
                });
              },
              child: Opacity(
                opacity: article.okay! ? 0.3 : 1,
                child: ListTile(
                  title: Text(
                    article.nom,
                    style: TextStyle(
                      decoration: article.okay!
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  leading:
                      Image(image: NetworkImage("$MEDIA_URL/${article.image}")),
                ),
              ));
        },
      ),
    );
  }

  Future<void> _fetchArticles() async {
    try {
      final response =
          await http.get(Uri.parse(CART_URL), headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $ACCESS_TOKEN',
      });



      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          _articles = responseData
              .map((a) => Article(
                  id: a["id"],
                  nom: a["name"],
                  image: a["image"],
                  okay: a["okay"]))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur lors de la requête : $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markArticle(int id, bool status) async {
    try {
      final boolParam = status ? "1" : "0";
      await http.patch(Uri.parse("$CART_URL/$id/$boolParam"),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $ACCESS_TOKEN',
          });
    } catch (e) {
      print("Erreur lors de la requête : $e");
    }
  }

  Future<void> _deleteCart() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await http.delete(Uri.parse(CART_URL), headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $ACCESS_TOKEN',
      });
      _fetchArticles();
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _dialogBuilder(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Avertissement'),
          content: const Text(
              'Voulez vous vraiment supprimer tout le contenu du panier ?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text(
                'Oui',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                _deleteCart();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Non'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
