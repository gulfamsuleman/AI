using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;

/// <summary>
/// http://stackoverflow.com/questions/66893/tree-data-structure-in-c-sharp#answer-10442244
/// </summary>
public class TreeNode<T>
{
	private readonly T _value;
	private readonly List<TreeNode<T>> _children = new List<TreeNode<T>>();

	public TreeNode(T value)
	{
		_value = value;
	}

	public TreeNode<T> this[int i]
	{
		get { return _children[i]; }
	}

	public TreeNode<T> Parent { get; private set; }

	public T Value { get { return _value; } }

	public ReadOnlyCollection<TreeNode<T>> Children
	{
		get { return _children.AsReadOnly(); }
	}

	public TreeNode<T> AddChild(T value)
	{
		var node = new TreeNode<T>(value) { Parent = this };
		_children.Add(node);
		return node;
	}

	public TreeNode<T> AddChild(TreeNode<T> value)
	{
		value.Parent = this;
		_children.Add(value);
		return value;
	} 

	public TreeNode<T>[] AddChildren(params T[] values)
	{
		return values.Select(AddChild).ToArray();
	}

	public TreeNode<T>[] AddChildren(params TreeNode<T>[] values)
	{
		return values.Select(AddChild).ToArray();
	}

	public bool RemoveChild(TreeNode<T> node)
	{
		return _children.Remove(node);
	}

	public void Traverse(Action<T> action)
	{
		action(Value);
		foreach (var child in _children)
			child.Traverse(action);
	}

	public IEnumerable<T> Flatten()
	{
		return new[] { Value }.Union(_children.SelectMany(x => x.Flatten()));
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

