"""Shortest paths over the explicit, schematic floor-1 graph (not metres)."""
import heapq
import math


def draft_route(campus: dict, start: int, destination: int, avoid_stairs: bool = False) -> dict:
    places = {p['id']: p for p in campus['places']}
    graph = campus.get('routing', {})
    attachments = graph.get('attachments', {})
    origin, target = places.get(start), places.get(destination)
    base = {'distance_m': None, 'duration_min': None, 'floor': 1,
            'accessibility_verified': False, 'avoid_stairs': avoid_stairs,
            'points': [], 'segments': [], 'steps': []}
    if not origin or not target:
        return {**base, 'status': 'unmapped', 'message': 'This place is not in the mapped catalogue.'}
    if any(p['map_key'] not in attachments for p in (origin, target)):
        return {**base, 'status': 'unmapped', 'message': 'One of these places has no traced floor-1 approach. Other floors and unsurveyed entrances cannot be routed yet.'}
    if any(p.get('access', 'public') != 'public' for p in (origin, target)):
        return {**base, 'status': 'restricted', 'message': 'This draft network only includes public approaches.'}
    if avoid_stairs and any(p['category'] == 'Stairs' for p in (origin, target)):
        return {**base, 'status': 'no_step_free_route', 'message': 'A staircase cannot be a step-free endpoint. Choose a corridor lift instead; accessibility remains unverified.'}
    if start == destination:
        return {**base, 'status': 'same_location', 'message': 'Start and destination are the same place.'}
    nodes = graph['nodes']
    adjacency = {key: [] for key in nodes}
    for a, b in graph['edges']:
        weight = math.dist(nodes[a], nodes[b])
        adjacency[a].append((b, weight))
        adjacency[b].append((a, weight))
    source, end = attachments[origin['map_key']], attachments[target['map_key']]
    queue = [(0, source)]
    costs, parents = {source: 0}, {}
    while queue:
        cost, node = heapq.heappop(queue)
        if cost > costs[node]:
            continue
        if node == end:
            break
        for neighbor, weight in adjacency[node]:
            updated = cost + weight
            if updated < costs.get(neighbor, math.inf):
                costs[neighbor], parents[neighbor] = updated, node
                heapq.heappush(queue, (updated, neighbor))
    if end not in costs:
        return {**base, 'status': 'no_route', 'message': 'No connected draft path was found.'}
    path = [end]
    while path[-1] != source:
        path.append(parents[path[-1]])
    path.reverse()
    def point(p):
        return [round(p['x'] * campus['width'], 3), round(p['y'] * campus['height'], 3)]
    points = [point(origin), *[nodes[n] for n in path], point(target)]
    segments = [{'from': a, 'to': b, 'approximate_door': index == 0 or index == len(points) - 2}
                for index, (a, b) in enumerate(zip(points, points[1:])) if a != b]
    points = [segments[0]['from'], *[s['to'] for s in segments]] if segments else points
    steps = [f'Start at {origin["name"]} on floor 1. Your start is manually selected, not GPS.']
    if any(n.startswith('spine_') for n in path):
        steps.append('Follow the grey main corridor along the highlighted path.')
    if target['block'].startswith('Block ') and target['map_key'].startswith(('d10', 'lift_block_')):
        steps.append(f'Enter the {target["block"]} side corridor and follow the highlighted branch.')
    steps.append(f'Approach {target["name"]}. The final connection is an approximate doorway/landing position.')
    return {**base, 'status': 'schematic_draft', 'points': points, 'segments': segments,
            'node_path': path, 'steps': steps,
            'start': origin['name'], 'destination': target['name'],
            'message': 'Draft traced from the map, not a verified navigation or accessible route. Dashed ends are approximate door connections.'}
