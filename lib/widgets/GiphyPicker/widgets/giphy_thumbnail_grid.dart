import 'package:giphy_client/giphy_client.dart';
import 'package:fiberchat/widgets/GiphyPicker/src/giphy_repository.dart';
import 'package:fiberchat/widgets/GiphyPicker/widgets/giphy_thumbnail.dart';
import 'package:flutter/material.dart';

/// A selectable grid view of gif thumbnails.
class GiphyThumbnailGrid extends StatelessWidget {
  final GiphyRepository repo;
  final ScrollController scrollController;
  final ValueChanged<GiphyGif> onSelected;
  const GiphyThumbnailGrid(
      {Key key,
      @required this.repo,
      this.scrollController,
      @required this.onSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        padding: EdgeInsets.all(10),
        controller: scrollController,
        itemCount: repo.totalCount,
        itemBuilder: (BuildContext context, int index) => GestureDetector(
            child: GiphyThumbnail(key: Key('$index'), repo: repo, index: index),
            onTap: () async {
              // display preview page
              // final giphy = GiphyContext.of(context);
              final gif = await repo.get(index);
              // unawaited(Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //         builder: (BuildContext context) => GiphyPreviewPage(
              //             gif: gif, onSelected: giphy.onSelected)))

              //             );
              onSelected(gif);
              Navigator.pop(context);
            }),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                MediaQuery.of(context).orientation == Orientation.portrait
                    ? 2
                    : 3,
            childAspectRatio: 1.6,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5));
  }
}
