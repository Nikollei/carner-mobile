import 'dart:convert';

import 'package:carner/Article.dart';
import 'package:carner/Constant.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

class Catalogue extends StatefulWidget {
  const Catalogue({super.key});

  @override
  State<Catalogue> createState() => _CatalogueState();
}

class _CatalogueState extends State<Catalogue> {
  late Future<List<Article>> _articlesFuture;

  @override
  void initState() {
    super.initState();
    _articlesFuture = _fetchArticles();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Article>>(
      future: _articlesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(
              child: Text('Erreur lors du chargement des articles'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucun article dans votre liste'));
        }

        final articles = snapshot.data!;
        return ListView.builder(
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index];
            return Dismissible(
              key: Key(article.id.toString()),
              // Utilisez l'ID de l'article comme clé unique
              background: Container(
                color: Colors.green,
                alignment: Alignment.centerLeft,
                child: const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ),
              secondaryBackground: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                child: const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Icon(Icons.remove, color: Colors.white),
                ),
              ),
              onDismissed: (direction) {
                if (direction == DismissDirection.startToEnd) {
                  _addArticleToList(article.id);
                } else {
                  _removeArticleToList(article.id);
                }
              },
              child: ListTile(
                title: Text(article.nom),
                leading:
                    Image(image: NetworkImage("$MEDIA_URL/${article.image}")),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Article>> _fetchArticles() async {
    try {
      final response =
      await http.get(Uri.parse(ARTICLE_URL), headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $ACCESS_TOKEN',
      });

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData
            .map((a) => Article(id: a["id"], nom: a["name"], image: a["image"], okay: a["okay"]))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Erreur lors de la requête : $e");
      return [];
    }
  }

  Future<void> _addArticleToList(int id) async {
    try {
      final response =
      await http.post(Uri.parse("$CART_URL/$id"), headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $ACCESS_TOKEN',
      });

      if (response.statusCode != 200 && response.statusCode != 409) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Erreur lors de l'ajout"), backgroundColor: Theme.of(context).colorScheme.error, duration: const Duration(seconds: 1)));
      }
    } catch (e) {
      print("Erreur lors de la requête : $e");
    }
  }

  Future<void> _removeArticleToList(int id) async {
    try {
      final response =
      await http.delete(Uri.parse("$CART_URL/$id"), headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $ACCESS_TOKEN',
      });

      if (response.statusCode != 200 && response.statusCode != 409) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Erreur lors de la suppression"), backgroundColor: Theme.of(context).colorScheme.error, duration: const Duration(seconds: 1)));
      }
    } catch (e) {
      print("Erreur lors de la requête : $e");
    }
  }
}
